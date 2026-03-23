#  Introduction

## Data sharding and data availability

The goal of the data availability layer is to overcome the bandwidth limitation, which in the case of Tezos is at the time of writing 512kB/15s (size of a block divided by its validation time). It is complicated to increase the capacity of a block from the chain without requiring the entire network to get a better internet connection and more powerful machines.

Since the bandwidth limitation is due to all nodes storing the same data and having to be able to send or retrieve it, the idea is to let nodes download a subset of the data (shard) and make it available, a technique known as [data sharding](https://www.digitalocean.com/community/tutorials/understanding-database-sharding), and commonly used to scale-out databases. Making the system as distributed as possible, the participants share the bandwidth and storage duty.

The data availability layer (DAL) implements sharding to store data blobs that aren’t interpreted or executed. Its role is to guarantee the availability of the data blobs, assuming a certain fraction of its nodes is providing the data.

Block producers use this layer to store batches of transactions which can be validated in two ways: either suppose at least one actor is honest and is checking the validity of the transactions and refutes invalid transactions ([optimistic rollups](https://ethereum.org/en/developers/docs/scaling/optimistic-rollups/)), or submit a proof – optionally in zero-knowledge – of the validity of the transaction ([zero-knowledge rollups](https://ethereum.org/en/developers/docs/scaling/zk-rollups/)).

The envisioned network being wholly open and operating in an adversarial environment, we need to ensure both the correctness and the availability of the data going through it by means of verifiable computation schemes and erasure coding.


## Idea of the cryptographic protocol

The data availability layer (DAL) reduces the storage strain on the blockchain by only storing on-chain constant-size cryptographic commitments to arbitrary data blobs called slots. The slots themselves are stored off-chain and are made available by the DAL.

A slot is encoded with an MDS (Maximum Distance Separable) code, and the resulting encoded slot is partitionned into shards, allowing retrieval of the slot with any subset of ``number_of_shards/MDS.redundancy_factor`` out of ``number_of_shards`` shards. By doing so, we can guarantee high data availability provided a certain fraction of the DAL nodes is storing and supplying the data. This fraction can be made as small as desired at the expense of a higher data redundancy `MDS.redundancy_factor`. MDS codes have no unnecessary redundancy.

Compatibility between the commitment scheme and the MDS code is achieved by using the KZG polynomial commitment scheme and Reed-Solomon codes. Indeed, Reed-Solomon codes are evaluations of polynomials and KZG allows proving and verifying evaluations of polynomials.

The DAL nodes can verify in constant time that they downloaded the correct shard using constant-sized [KZG proofs](https://www.iacr.org/archive/asiacrypt2010/6477178/6477178.pdf) (see function `verifyEval` in section 3.3) and the slot commitment. This mitigates the barriers in terms of bandwidth and storage to participate in the DAL network so that more actors can increase its efficacy and security -- to prevent data availability attacks, for instance.

The L1 can also verify in constant time that it downloaded the correct slot segment called page it queried using KZG proofs and the slot commitment.

A challenge is to keep the proving time for the shard proofs almost proportional to the length $n$ of the slot encoded with the MDS code: we've chosen and implemented a technique to produce the proofs in time $O(n \log n)$ (see https://eprint.iacr.org/2023/033.pdf).

We can sum up the construction as follows:
:::info
**Link Reed-Solomon ⬌ Polynomial commitment**. A portion of Reed-Solomon encoding is a set of evaluations of a polynomial at known points, which can be proved and verified with a polynomial commitment.

**Link polynomial commitment ⬌ vector commitment**. A vector commitment can be obtained from a polynomial commitment by interpreting the coefficients of the vector as evaluations of a polynomial through polynomial interpolation.

**Link Reed-Solomon ⬌ vector commitment**. Follows from the above: we can thus prove and verify a Reed-Solomon encoding valid.
:::


## Organization of this document

We first present the techniques to achieve this goal (sometimes with more details than actually needed to understand the protocol, feel free to skip), then formalize the protocol, and finally justify some implementation choices.


# Algorithms of the cryptography for the DAL
## The Fast Fourier Transform

### Discrete Fourier Transform (DFT)

Let $\mathbb{F}$ be a field and $\omega\in\mathbb{F}^\times$ a [primitive $n$-th root of unity](https://en.wikipedia.org/wiki/Root_of_unity#General_definition) (so by definition the natural number $n$ divides the order of the multiplicative group $\mathbb{F}^\times$).
The DFT matrix is defined by:
$$F_\omega=\begin{bmatrix}
    1 & 1      & 1        & \dots& 1\\
    1 & \omega & \omega^2 & \dots & \omega^{n-1}\\
    1 & \omega^2 & \omega^4 & \dots & \omega^{2(n-1)}\\
    \vdots &\vdots &\vdots & \ddots & \vdots\\
    1 & \omega^{n-1} & \omega^{2(n-1)} & \dots  & \omega^{(n-1)^2}
    \end{bmatrix}$$

and the inverse DFT matrix is given by $F_{\omega^{-1}}$.

The discrete Fourier transform of length $n$ is the $\mathbb{F}$-linear map:
$$\begin{align*}
    \text{DFT}_{\omega}: \mathbb{F}^n &\to \mathbb{F}^n\\ \boldsymbol{x} &\mapsto \boldsymbol{y}= F_{\omega} \boldsymbol{x}= \big(\sum_{i=0}^{n-1} x_i \cdot\omega^{i j}\big)_{j\in ⟦0,n-1⟧}
\end{align*}$$
which evaluates a polynomial from $\mathbb{F}[x]$ of degree strictly less than $n$ at the distinct points $1, \omega, \dots, \omega^{n-1}$. The group elements $1, \omega, \dots, \omega^{n-1}$ being distinct for the following reason: let $x\in\mathbb{F}^\times$ a group element of order $n$; for any $0<m < n, x^m \neq 1$, and $x^n=1$. If $x^j = x^k$ for $1 \leq j < k \leq n$, then $x^{k - j}= 1$ with $0 < k - j < n$, a contradiction.

For any $0\leq i,j<n$:
$$\begin{align*}
    (F_\omega F_{\omega^{-1}})_{i,j} &= \sum_{k=0}^{n-1} \omega^{jk} (\omega^{-1})^{ik}\\
    &=  \sum_{k=0}^{n-1} \omega^{(j-i)k}\\
    &= 0 \text{ if } i\neq j \text{ or } n \text{ if } i=j.
\end{align*}$$
As in any field, $d\in\mathbb{N}\setminus \{ 0\}$, for a primitive $n$-th root of unity $\omega$, $1 + \omega^d +\dots+ \omega^{d(n-1)} = (1-(\omega^n)^d)/(1-\omega^d) = 0$ since $\omega^n=1$, and $\omega^{-1}$ is also a primitive $n$-th root of unity.

Thus $F_\omega F_{\omega^{-1}}=n\times \text{Id}_n$, which in turn implies $(\text{DFT}_\omega)^{-1} = n^{-1} \text{DFT}_{\omega^{-1}}$.
The inverse discrete Fourier transform is thus defined if $n$ is invertible in $\mathbb{F}$ (the characteristic of $\mathbb{F}$ is strictly greater than $n$).

When $\mathbb{F}$ is a finite field this transform is also called Number Theoretic Transform (NTT).

Note that we can consider a variant of the DFT where the vector holds points of an elliptic curve group defined over a finite field $E(\mathbb{F}_p)$, which we call EC-DFT. The addition is then the elliptic curve point addition and the multiplication with roots of unity is the elliptic curve scalar multiplication (the roots of unity being defined over a prime field can be mapped to scalars).

## Convolution product with the DFT

One can check that the $n$-DFT is an homomorphism from $(\mathbb{F}^n,*)$ to $(\mathbb{F}^n,\odot)$ where $*$ is the convolution product^[$(f\times g)(x) = \sum_k h_k$ where $h_k=∑_j a_{k-j} b_j$.] and $\odot$ is the element-wise multiplication:
$$\text{DFT}_{\omega}(A*B) = \text{DFT}_\omega(A)\odot\text{DFT}_\omega(B)$$
from which
$$A*B=\text{DFT}^{-1}_{\omega}(\text{DFT}_\omega(A)\odot\text{DFT}_\omega(B))$$ follows.

:::info
One way to see it is to remark that the DFT for field elements is a ring isomorphism (with inverse DFT<sup>-1</sup>) given by the Chinese Remainder Theorem (CRT)

$$\mathbb{F}^n\cong \mathbb{F}[x]/\langle x^n-1\rangle \cong \Pi_{0\leq i < n}\mathbb{F}[x]/\langle x-\omega^i\rangle.$$

The first isomorphism corresponds to the fact that $\mathbb{F}[x]/\langle x^n-1\rangle$ is a ring (of polynomials in $\mathbb{F}[x]$ taken modulo $x^n-1$) and an $\mathbb{F}$-vector space of dimension $n$. The second one is the CRT factorization of $\mathbb{F}[x]/\langle x^n-1\rangle$ as the ideals $\langle x-\omega^i\rangle$ are pairwise coprime so their intersection is their product $\langle x^n-1\rangle$.
Indeed, the DFT maps $f\in\mathbb{F}[x]_{< n}$ to $(f(\omega^i)=f(x) \mod (x-\omega^i))_{i\in ⟦0,n-1⟧}$. The inverse map comes down to the [Lagrange interpolation](https://en.wikipedia.org/wiki/Chinese_remainder_theorem#Lagrange_interpolation) (based on partial fraction decomposition) or [Bézout](https://en.wikipedia.org/wiki/B%C3%A9zout%27s_identity#For_polynomials) (based on Bézout's identity, whose coefficients can be computed with the extended Euclidean algorithm).
:::


### The Fast Fourier Transform (FFT)

The FFT from Cooley and Tukey (and Gauss) splits the computation of a DFT of size $n=n_1 n_2$ into the computations of $n_2$ DFTs of size $n_1$ (inner sum) and $n_1$ DFTs of size $n_2$ (outer sum), for $0\leq k < n_1$ and $0\leq l < n_2$:

$$\begin{equation*}
    P(\omega^{k+n_1 l}) = \sum_{i=0}^{n_2-1}\Bigg(\sum_{j=0}^{n_1-1} P_{i+n_2 j} (\omega^{n_2})^{jk}\Bigg) (\omega^{n_1})^{i l} \omega^{i k}.
\end{equation*}$$


What follows is a reproduction of the derivation of the above FFT expression from the DFT from the section 2.3 of [An Approach to Low-power, High-performance, Fast Fourier Transform Processor Design, Bevan M. Baas, 1999](https://redirect.cs.umbc.edu/~tinoosh/cmpe691/docs/phd-thesis-FFT.pdf). The input vector $\boldsymbol{x}$ and output vector $\boldsymbol{y}$ are reshaped to form $n_1\times n_2$ matrices $X$ and $Y$ as follows: for integers $A,B,C,D$, $0\leq i,k < n_1$, $0\leq j,l < n_2$, $X_{i,j}=x_{A i + B j \mod n}$ and $Y_{k,l}=y_{C k + D l \mod n}=P(\omega^{C k + D l})$.




Plugging this reindexing into the DFT equation we obtain (where $\omega_k=\omega^{n/k}$, and is a primitive $k$-th root of unity):
$$
y_j = \sum_{i=0}^{n-1} x_i\ \omega_n^{ij}
\implies
Y_{k,l} = \sum_{i=0}^{n_1-1} \sum_{j=0}^{n_2-1} X_{i,j}\ \omega_n^{(Ai+Bj)(Ck+Dl)}.
$$

With a column-wise reshape of $\boldsymbol{x}$ (ie. $A=n_2, B=1$) and row-wise reshape of $\boldsymbol{y}$ (ie. $C=1, D=n_1$), we find the Cooley-Tuckey FFT:

$$
\begin{align*}
Y_{k,l} &= \sum_{i=0}^{n_1-1} \sum_{j=0}^{n_2-1} X_{i,j}\ \omega_n^{(n_2 i+j)(k+n_1 l)}\\
&= \sum_{i=0}^{n_1-1} \sum_{j=0}^{n_2-1} X_{i,j}\ \omega_n^{n_2 i k +  jk +j n_1 l}\\
&= \sum_{i=0}^{n_1-1} \Bigg( \Bigg [\sum_{j=0}^{n_2-1} X_{i,j} \  \omega_{n_2}^{jl} \Bigg] \omega_n^{jk}\Bigg)\omega_{n_1}^{i k}\quad (*)\\
&= \sum_{j=0}^{n_2-1} \Bigg (\sum_{i=0}^{n_1-1} X_{j,i} \  \omega_{n_1}^{ik} \Bigg) \omega_{n_2}^{jl}\omega_n^{j k}.
\end{align*}
$$

#### Radix-2 decimation in time vs. decimation in frequency


The terminology comes from the Digital Signal Processing community where the DFT maps a signal (DFT input) to its frequencies (DFT output).

The radices are the prime factors from the decomposition of the DFT domain size $n$. Typically $n=2^k$ so the FFT is radix-2. We consider $n=2^k$.

##### Decimation in **time** (DIT)
From $(*)$, choosing $n_1=n/2$, $n_2=2$: the **input sequence of the DFT $\boldsymbol{x}$ is decomposed** into the even- and odd-indexed subsequences $X_{i,0}=x_{2i}$ and $X_{i,1}=x_{2i+1}$:
$$
Y_{k,l}=P(\omega^{k+(n/2)l})=\sum_{i=0}^{n/2-1} x_{2i}\omega_{n/2}^{ik} + \omega_n^{(n/2)l+k}\sum_{i=0}^{n/2-1} x_{2i+1}\omega_{n/2}^{ik}
$$
which amounts to the "textbook FFT formula", with a change of variable, and for $0\leq k<n$:
$$
P(\omega^{k})=\sum_{i=0}^{n/2-1} x_{2i}\omega_{n/2}^{ik} + \omega_n^{k}\sum_{i=0}^{n/2-1} x_{2i+1}\omega_{n/2}^{ik}.
$$
Thus we obtain a recursive definition of the DFT: $\text{DFT}_{\omega_n}(\{x_k\})=\text{DFT}_{\omega_{n/2}}(\{x_{2i}\})+\omega_n^k\text{DFT}_{\omega_{n/2}}(\{x_{2i+1}\})$.

<!-- An interesting observation due to Bernstein is that the above expression is a transformation of the form $\boldsymbol{F}[x]/\langle x^n - 1 \rangle \to \boldsymbol{F}[x]/\langle x^{n/2} - 1 \rangle\times \boldsymbol{F}[x]/\langle x^{n/2} + 1 \rangle\cong \boldsymbol{F}[x]/\langle x^{n/2} - 1 \rangle\times \boldsymbol{F}[x]/\langle \tilde{x}^{n/2} - 1 \rangle$ with $\tilde{x}=\omega_n x$.-->


##### Decimation in **frequency** (DIF)
From $(*)$, choosing $n_1=2$, $n_2=n/2$: the **output sequence of the DFT $\boldsymbol{y}$ is decomposed** into the even- and odd-indexed subsequences $Y_{0,l}=P(\omega^{2l})$ and $Y_{1,l}=P(\omega^{2l+1})$:
$$\begin{align*}
Y_{k,l}=P(\omega^{k+2l})&=\sum_{i=0}^{n/2-1} x_{i}\omega_{n}^{i(2l+k)} + \sum_{i=0}^{n/2-1} x_{n/2+i}\omega_{n}^{(n/2+i)(2l+k)}\\
&=\sum_{i=0}^{n/2-1} (x_{i} +(-1)^k x_{n/2+i})\omega_{n}^{i(2l+k)}\\
&=\sum_{i=0}^{n/2-1} (x_{i} +(-1)^k x_{n/2+i})\omega_{n/2}^{il}\omega_{n}^{ik}.\end{align*}$$
Hence the recursive definition of the DFT: $\{ y_{2i} \}=\text{DFT}_{\omega_{n/2}}(\{x_i+x_{n/2+i}\}_{i\in ⟦0,n/2-1⟧})$ and $\{ y_{2i+1} \}=\text{DFT}_{\omega_{n/2}}(\{(x_i-x_{n/2+i})\omega_n^i \}_{i\in ⟦0,n/2-1⟧})$.


There is a nice symmetry: in the DIT, the input sequence decomposed in even- and odd- indexed subsequences, and the output sequence is decomposed in top and bottom subsequences; and vice-versa for the DIF.

:::info
The current implementation is an iterative version of the decimation in time FFT.
:::


### Prime factor algorithm (FFT variant)

This algorithm allows computing FFTs on domains of size $n$ whose factorization is included in the factorization of $|\mathbb{F}_r^{\times}|=r-1$. Let $\omega$ be a primitive $n$-th root of unity.

When $n_1$ and $n_2$ are coprime then the Chinese Remainder Theorem (CRT) allows to re-index the DFT of size $n$ in such a way the inner DFTs don't have to be multiplied by the $n$ extra factors $\omega^{iu}$ (https://www.researchgate.net/publication/3316018_Index_mappings_for_the_fast_Fourier_transform).

We start from the expression of the DFT for $k=0,\dots, n-1$:
$$P(\omega^k) = \sum_{l=0}^{n-1} P_l \omega^{l k}.$$
We re-index both input and output coefficients $l$ and $k$ thanks to the ring isomorphism $\mathbb{Z}_n ≅ \mathbb{Z}_{n_1} \times \mathbb{Z}_{n_2}$ given by the CRT. It turns out that certain combinations of input and output mappings allow getting rid of the extra factors $\omega^{iu}$. Let's take as input mapping the CRT forward mapping $\mathbb{Z}_n \xrightarrow{} \mathbb{Z}_{n_1} \times \mathbb{Z}_{n_2} : l \mapsto (l \mod n_1, l \mod n_2)$. Hence, by Bézout for $i=l\mod n_1$, $j=l\mod n_2$, $t_1 = (1/n_1 \mod n_2)$ and $t_2=(1/n_2 \mod n_1)$, we obtain $P_l=P_{i n_2 t_2 + j n_1 t_1}$. As output mapping, we take the Good's mapping $\mathbb{Z}_{n_1} \times \mathbb{Z}_{n_2} \xrightarrow{} \mathbb{Z}_n : (i, j)\mapsto j n_1+i n_2 \mod n$. We could also have permuted the input and output mappings. Applying the two mappings, we get
\begin{align*}
  P(\omega^{ k n_1 + l n_2 }) &= \sum_{i=0}^{n_1-1} \sum_{j=0}^{n_2-1} P_{i n_2 t_2 + j n_1 t_1} \omega^{(i n_2 t_2 + j n_1 t_1)(l n_2 + k n_1)}  \\
  &= \sum_{i=0}^{n_1-1} \sum_{j=0}^{n_2-1} P_{i n_2 t_2 + j n_1 t_1} \omega^{i n_2 t_2 l n_2} \omega^{i n_2 t_2 k n_1} \omega^{j n_1 t_1 l n_2} \omega^{j n_1 t_1 k n_1} \\
  &= \sum_{i=0}^{n_1-1} \sum_{j=0}^{n_2-1} P_{i n_2 t_2 + j n_1 t_1} \omega^{i n_2 t_2 l n_2}\omega^{j n_1 t_1 k n_1}  \\
  &= \sum_{i=0}^{n_1-1} \sum_{j=0}^{n_2-1} P_{i n_2 t_2 + j n_1 t_1} \omega_{n_1}^{i t_2 l n_2}\omega_{n_2}^{j t_1 k n_1}  \\
  &= \sum_{i=0}^{n_1-1} \Big(\sum_{j=0}^{n_2-1} P_{i n_2 t_2 + j n_1 t_1}\omega_{n_2}^{jk} \Big) \omega_{n_1}^{i l}.
\end{align*}


So in the same way as implied by the equation $(*)$, we compute $n_1$ FFTs of length $n_2$, transpose the $n_1\times n_2$ matrix, and compute $n_2$ FFTs of length $n_1$. The cost of the transposition is somewhat negligible compared to the FFTs since it only changes the data layout.


Complexity: assuming $n_2=2^k$ and $n_1=p$ for small prime $p$: $O(2^k(p\times k+ p^2))$.


## Reed-Solomon erasure codes

### MDS codes

We need an MDS (Maximum Distance Separable) code: a linear code of dimension $k$ and length $n$ over a finite field $\mathbb{F}$ (a vector subspace of dimension $k$ of $\mathbb{F}^n$), which reaches the Singleton bound (the minimal Hamming distance between any two codewords is $d=n-k+1$), and so provides the maximum erasure-correcting capability possible (as a linear code cannot verify $d > n - k + 1$, again by the Singleton bound). So we can correct up to $d-1=n-k$ erasures by finding the closest codeword under the Hamming distance. A generating matrix $G\in\mathbb{F}^{n\times k}$ of a linear code $\mathcal{C}$ is defined by $\mathcal{C}=\text{Column-span}({G})=\{ {G}\boldsymbol{x}^T : \boldsymbol{x}\in \mathbb{F}^k \}$. The property that any $k$ coefficients $\boldsymbol{\tilde{c}}$ of a codeword  $\boldsymbol{c}$ determine it, comes from the fact that any set of $k$ rows of its generating matrix forms a full rank $k\times k$ matrix $A$ (the equation $A\boldsymbol{c}^T=\boldsymbol{\tilde{c}}^T$ where $\boldsymbol{c}$ is the unknown has a unique solution, as $A$ is invertible).

### Reed-Solomon codes
Let $\mathbb{F}$ be a prime field of order $r$. Let $n=\alpha k$ such that $n | r - 1$. Let $\omega\in\mathbb{F}$ be a [primitive $n$-th root of unity](https://mathworld.wolfram.com/PrimitiveRootofUnity.html).

:::info
Let's fix a prime field $\mathbb{F}_p$ for prime $p$. Knowing a generator $g$ of $\mathbb{F}_p^\times$, $g^{(p-1)/k}$ is a primitive $k$-th root of unity in the field. But how to find a primitive root without a generator of $\mathbb{F}_p^\times$?

1. For $n$ and $m$ relatively prime, the product of a primitive $n$-th root of unity $\zeta_n$ and a primitive $m$-th root of unity $\zeta_m$ is a primitive $nm$-th root of unity.
    _Proof_: First $\zeta_n\zeta_m$ is a $nm$-th root of unity since $(\zeta_n\zeta_m)^{nm}=1$. Suppose there exists $k$ for which $(\zeta_n\zeta_m)^k=1$. Then $\zeta_m^{nk}=(\zeta_n\zeta_m)^{nk}=1$. Thus $m|nk$, but since $n$ and $m$ are coprime, $m|k$. In the same manner $n|k$. Thus $k|nm$ as $n$ and $m$ don't share any common factors. So $\zeta_n \zeta_m$ is a primitive $nm$-th root of unity.
2. For $n|p-1$, $\zeta\in\mathbb{F}_p^\times$ is a primitive $n$-th root of unity if and only if $\zeta^n=1$ and for all $m<n, m|n$, $\zeta^m\neq 1$.
_Proof_: If $\zeta$ is a primitive $n$-th root of unity then by definition $\zeta^n=1$ and for all $m<n$, $\zeta^m\neq 1$ so in particular for all $m|n$, $\zeta^m\neq 1$. For the other implication: we know that $\zeta^n=1$ and for all $m|n$, $\zeta^m\neq 1$. In particular, $\zeta$ is a $n$-th root of unity, so its order $k$ divides $n$ by Lagrange. Since $k<n$ then $k|n/p'$ for some prime factor $p'$ of $n$. Let's call $m=n/p'|n$. Hence there exists $l$ such $kl=m$, and so $\zeta^m=(\zeta^k)^l=1$. Contradiction! Thus $\zeta$ is primitive $n$-th root of unity, ie. $\zeta$ has order $n$.
3. For a prime $q$ and the greatest $\alpha$ such that $q^\alpha|p-1$, sample a primitive $q^\alpha$-th root of unity: sample $x\in \mathbb{F}_p^{\times}$, if $x^{(p-1)/q}\neq 1$ then $\zeta=x^{(p-1)/q^\alpha}$ is a primitive $q^\alpha$-th root of unity in $\mathbb{F}_p$.
    _Proof_: We notice that $\zeta^{q^\alpha}=x^{p-1}=1$ and $\zeta^{q^{\alpha-1}}=x^{(p-1)/q}\neq 1$. Is $\zeta^{q^d}\neq 1$ for $0\leq d<\alpha-1$? Assume there exists $0\leq d<\alpha-1$ such that $\zeta^{q^d}=x^{(p-1)/q^{\alpha-d}}=1$. Then $(\zeta^{q^d })^{q^{\alpha-d-1}}=x^{(p-1)/q^{\alpha-d-(\alpha-d-1)}}=x^{(p-1)/q}=1$, a contradiction.
For the prime decomposition $k=\Pi_i p_i^{\alpha_i}|p-1$, a primitive $k$-th root of unity in $\mathbb{F}_p$ is obtained by multiplying each primitive $p_i^{\alpha_i}$-th root of unity found through 3. thanks to 1.
:::

We consider the Reed-Solomon code of parameters $[n,k,d=n-k+1]$ and evaluation points, $\boldsymbol{\omega}=(1,\omega,\omega^2,\dots,\omega^{n-1})$ the subgroup of the $n$-th roots of unity. We denote it $\text{RS}(n,k,\boldsymbol{\omega})≔ \{ (f(\omega^i))_{i\in⟦ 0,n-1 ⟧} | f\in\mathbb{F}[x] \wedge \deg f<k \}$.

RS has rate $R=k/n=1/\alpha$. To a vector $\boldsymbol{f}$ we associate the polynomial $f(x)=\sum_i f_i x^i$, and reciprocally. RS is a linear code, whose generating matrix is the following Vandermonde matrix, for which every square submatrix is invertible, so RS is indeed MDS:
$$
    \begin{bmatrix}
    1 & \omega_1 & \omega_1^2 & \dots & \omega_1^{k-1}\\
    1 & \omega_2 & \omega_2^2 & \dots & \omega_2^{k-1}\\
    \vdots & & & \ddots & \vdots\\
    1 & \omega_n & \omega_n^2 & \dots  & \omega_n^{k-1}
    \end{bmatrix}.
$$
### Encoding
Encoding a message $\boldsymbol{m}=(m_0,\dots,m_{k-1})\in\mathbb{F}^k$ amounts to evaluate its associated polynomial $m(x)=\sum_{i=0}^{k-1} m_i x^i$ at the evaluation points $\boldsymbol{\omega}$. This can be done with an $n$-points discrete Fourier transform supported by $\mathbb{F}$ in time $\mathcal{O}(n\ \log\ n)$:

:::info
Input: $\boldsymbol{m}=(m_0,\dots,m_{k-1})\in\mathbb{F}^k$
Output: $\boldsymbol{c}=(c_0,\dots,c_{n-1})\in \text{RS}(n,k,\boldsymbol{\omega})$
Return $\text{FFT}_{n} (\text{IFFT}_{k}(\boldsymbol{m}) \mathbin\Vert \boldsymbol{0}_{\mathbb{F}^{n-k}})$
:::

### Decoding from erasures

As we saw earlier, we can decode a codeword $\boldsymbol{c}\in \text{RS}(n,k,\boldsymbol{\omega})$ with at most $d-1=n-k$ erasures, i.e. from at least $k$ components of $\boldsymbol{c}$.

Without loss of generality, let $\tilde{\boldsymbol{c}}=({c}_0,\dots,{c}_{k-1})$ be the received codeword with erasures, the first $k$ components of a codeword. We can retrieve the original message $\boldsymbol{m}$ with any $k$ components of $\boldsymbol{c}$ thanks to the Lagrange interpolation polynomial, where the $x_i$ are the evaluation points of $\tilde{\boldsymbol{c}}$

$$m(x)=\sum_{i=0}^{k-1} {c}_i  \prod_{\substack{j=0 \\ j\neq i}}^{k-1} \frac{x-x_j}{x_i - x_j}.$$

As detailed in https://arxiv.org/pdf/0907.1788v1.pdf, the idea is to rewrite $m(x)$ as a product of two polynomials $A(x)$ and $B(x)$ so that the convolution theorem allows us to recover $m(x)$ using FFTs in ${O}(n\ \log\ n)$. (The authors consider sums to $n-1$ while we can consider sums to $k-1$ since $m(x)$ has degree $k$.)

To do so, let
$$A(x) ≔ \prod_{i=0}^{k-1} (x-x_i), \quad A_i(x) ≔\prod_{\substack{j=0\\ j\neq i}}^{k-1} (x-x_j).$$

Let $n_i ≔ \dfrac{{c}_i}{A_i(x_i)}$.

The interpolation polynomial becomes:
$$m(x)=A(x) \sum_{i=0}^{k-1}\frac{ {c}_i }{(x - x_i) A_i(x_i)} = A(x)\sum_{i=0}^{k-1} \frac{n_i}{x-x_i}.$$

Note that $A_i(x_i)\neq 0$ by definition, so it is invertible in $\mathbb{F}$.

In order to replace the costly product $A_i(x)$ in this expression, we use the fact that the formal derivative $A'(x)$ of $A(x)$ satisfies for all $i\in⟦ 0, k-1 ⟧$: $A'(x_i)=A_i(x_i)$.
So we can compute $(A_i(x_i))_i$ by evaluating $A'(x)$ at the points $\boldsymbol{\omega}$ with an FFT.

Indeed:
$$ A'(x)= (\prod_{i=0}^{k-1} (x-x_i))' = \sum_{i=0}^{k-1} (x-x_i)' \prod_{\substack{j=0\\ j\neq i}}^{k-1} (x-x_j)=\sum_{j=0}^{k-1}  A_j(x).$$
So $A'(x_i)=\sum_{j=0}^{k-1} A_j(x_i)=A_i(x_i)$ as the other polynomials $A_j(x)$ have $x_i$ as root.

Writing the fraction $\frac{1}{x_i-x}=\sum_{j=0}^{\infty} \frac{x^j}{x_i^{j+1}}$ as a formal power series, we obtain
\begin{align*}
m(x)/A(x)=\sum_{i=0}^{k-1} \frac{n_i}{x-x_i} \mod x^k &= -\sum_{i=0}^{k-1} \Big(\sum_{j=0}^{k-1} \frac{n_i}{x_i^{j+1}} x^j\Big).
\end{align*}

But if we let $N(x)≔\sum_{i=0}^{k-1} \dfrac{n_i}{x_i} x^{i}$ then
$$ \sum_{i=0}^{k-1} \frac{n_i}{x-x_i} \mod x^k = - \sum_{j=0}^{k-1} N(x_i^{-j})x^j ≕ -B(x). $$

$B(x)$ is thus given by the first $k$ components of $n\times \text{IFFT}_n(\boldsymbol{N})$.


So the product is given by the convolution theorem, and by linearity of the DFT and pairwise product:
\begin{align*}
\boldsymbol{m} &= \boldsymbol{A} * (-\boldsymbol{B}) =  -\text{IFFT}_{2k}(\text{FFT}_{2k}(\boldsymbol{A}) \odot \text{FFT}_{2k}(\boldsymbol{B})).
\end{align*}
 The total cost is $O(k\ \log^2\ k + n\ \log\ n)$: the first term accounts for the computation of the product for $A(x)$ with a divide and conquer approach for the multiplication of its factors with FFT multiplication, and the second one for the other steps.

### Sharding


We will split the codewords into chunks to be sent to the data availability layer.
For this purpose, let $s$ be the number of shards, $l=n/s$ the length of a shard, and $\omega$ a primitive $n$-th root of unity.

The domain of evaluation is then split into cosets: $\langle \omega \rangle=\bigsqcup_{i\in⟦ 0, s-1 ⟧ }  \Omega_i$, for $\Omega_0 = \{\omega^{s j}\}_{j\in⟦ 0,\ l-1 ⟧}$ and $\Omega_i = \omega^i \Omega_0$.

For a set of $k/s$ shard indices $Z\subseteq \{0, s-1\}$, we reorganize the product $A(x)=\prod_{i=0}^{k-1} (x-x_i)$ into $$A(x)=\prod_{\substack{i\in Z\\ |Z|=\frac{k}{s}}}  \underbrace{\prod_{\omega'\in\Omega_{i}} (x-\omega')}_{Z_i}.$$
We notice that $Z_0(x)=x^{|\Omega_0|}-1$ (as its roots are the elements of a group of order dividing $|\Omega_0|$) entails $Z_i(x)=x^{|\Omega_0|}-\omega^{i |\Omega_0|}$ (multiplying all terms by a constant $\omega^{i}$ in an integral domain), which is as sparse as it can be. More formally: every element of $\Omega_i$ is of the form $\omega^i \omega^{s j}$ for $j\in ⟦ 0,\ l-1 ⟧$. Thus
$$ Z_i(\omega^i \omega^{s j})=(\omega^i \omega^{s j})^{|\Omega_0|}-\omega^{i|\Omega_0|}=(\omega^i)^{|\Omega_0|} (\omega^{s j})^{|\Omega_0|}-\omega^{i|\Omega_0|}=\omega^{i|\Omega_0|} 1-\omega^{i|\Omega_0|}=0.$$
So every element of $\Omega_i$ is a root of $Z_i(x)$. Moreover, $Z_i(x)$ is a degree $|\Omega_0|=l$ polynomial so has at most $l$ roots: $Z_i(x)$'s only roots are $\Omega_i$.


With this little observation, we've reduced the number of leaves of the recursion tree for the divide-and-conquer multiplication of the factors of $A(x)$ from $k$ to $k/s$.


## BLS12-381 pairing-friendly elliptic curve


Definition of a pairing (adapted from https://hal.science/hal-01579628)
A pairing is a map $e:\mathbb{G}_1\times\mathbb{G}_2\xrightarrow{}\mathbb{G}_T$ between finite cyclic abelian groups $\mathbb{G}_1=\langle g_1\rangle,\mathbb{G}_2=\langle g_2 \rangle$, and $\mathbb{G}_T=\langle g_T \rangle$, verifying:

- $e$ is bilinear: $\forall a,c\in\mathbb{G}_1, \forall b\in\mathbb{G}_2, e(a+c,b)=e(a,b)e(c,b)$ and $\forall a\in\mathbb{G}_1, \forall b,c\in\mathbb{G}_2, e(a,b+c)=e(a,b)e(a,c)$.
- $e(g_1,g_2)=g_T$.
- $e$ is non-degenerate: for any $a\in\mathbb{G}_1$, there is $b\in\mathbb{G}_2$ such that $e(a,b)\neq 1$, and for any $b\in\mathbb{G}_2$ there is $a\in\mathbb{G}_1$ such that $e(a,b)\neq 1$.


To be suited to cryptography, the computation of $e$ needs to be efficient and $e$ must be computationally hard to inverse. Certain elliptic curves allow constructing such pairings, and are called pairing-friendly for this reason.

We will consider pairings where $\mathbb{G}_1$ and $\mathbb{G}_2$ are subgroups of a well-chosen elliptic curve, so $e$ also verifies $\forall\lambda\in\mathbb{F},  e(a,\lambda b)=e(\lambda a, b)$, which follows from the bilinearity.

The blog post https://electriccoin.co/blog/new-snark-curve/ and article https://hackmd.io/@benjaminion/bls12-381 are good introductions to the subject.

## Commitment scheme

A commitment scheme allows a sender to commit to a secret value, and to reveal it afterward to a receiver. It satisfies the following two properties:

- **Hiding property**. The receiver must know nothing about the committed value until it is revealed.
- **Binding property**. The sender cannot change the secret value once committed.



More formally, as defined in https://eprint.iacr.org/2022/188:
Definition of a commitment scheme:
A commitment scheme is a tuple of three algorithms ($\textsf{Setup}$, $\textsf{Commit}$, $\textsf{Verify}$) such that

- $\textsf{Setup}$ is an algorithm that on input $1^\lambda$ ($\lambda$ being the desired security parameter), outputs some bounded public parameters PP containing a definition of the value space $V$, randomness space $S$ and commitment space $C$.
- $\textsf{Commit}$ is a deterministic polynomial-time algorithm that, on input the public parameters PP, a value $v\in V$ and a randomness $r\in S$, outputs a commitment $c\in C$.
- $\textsf{Verify}$ is a deterministic polynomial-time algorithm that, on input the public parameters PP, a value $v\in V$, a commitment $c\in C$ and a randomness $r\in S$, outputs $\textsf{true}$ or $\textsf{false}$.




## Trusted setups

The trusted setup is composed of the committing key $\textsf{CK}$ and verifying key $\textsf{VK}$ which are used to commit and verify, respectively. They are often referred to as structured reference strings (SRS). The secret $\tau\in\mathbb{F}_p^\times$ must be destroyed after generation, as the scheme relies on the assumption that finding it given the SRS is a computationally hard problem provided that the order of the groups isn't subject to attacks (e.g. MOV reduction, a subexponential attack based on pairings for the discrete logarithm on elliptic curves). It is a generalization of the discrete logarithm assumption, called $d$-strong Diffie-Hellman assumption.



## KZG polynomial commitment scheme

KZG is a polynomial commitment scheme whose distinguishing features are its constant-sized commitments, proofs, and its constant-time verification.

It operates on subgroups of elliptic curves over finite fields $\mathbb{G}_1=\langle g_1 \rangle$, $\mathbb{G}_2=\langle g_2 \rangle$, and $\mathbb{G}_T=\langle g_T \rangle$ of prime order $r$ ($r$ depends on the chosen security level $\lambda$), for which a pairing $e:\mathbb{G}_1 \times \mathbb{G}_2 \mapsto \mathbb{G}_T$ exists. From now on, we adopt the convenient notation for elliptic curve multiplication: $[n]_1=n g_1$ and $[n]_2=n g_2$.

As a commitment scheme, it is a tuple of deterministic polynomial-time algorithms commit, proveEval and verifyEval such that
1. Commit, on input a polynomial, returns a commitment:
:::info
$\textsf{commit}(\textsf{CK}, f(x)):$
1. $\textbf{assert } \deg(f(x)) < d$
2. $\textbf{return }c\gets \prod_{i=0}^{n-1} p_i[\tau^i]_1=[f(\tau)]_1$
:::
2. ProveEval outputs a proof $\pi$ that $f$ evaluates to $f(z)$ in $z$:
:::info
$\textsf{proveEval}(\textsf{CK}, f(x), z):$
1. $q(x)\xleftarrow{}\frac{f(x)-f(z)}{x-z}$
2. $\textbf{return } \pi\gets\textsf{commit}(\textsf{CK}, q)$
:::
3. VerifyEval, on input a proof, outputs true if the given proof testifies that the committed polynomial $f$ evaluates to $y$ in $z$ (using the pairing $e$):
:::info
$\textsf{verifyEval}(\textsf{VK}, c, z, y, \pi):$
1. $\textbf{return } e(c-[y]_1, g_2) \overset{?}{=} e(\pi, [\tau]_2 - [z]_2)$
:::



The crux of KZG is that if $f(x)$ has $z$ as root, then the quotient $q(x)$ is well-defined. This comes from the euclidean division of $f(x)$ by $x-z$: $f(x)=q(x)(x-z)+r(x)$, $\deg r(x) = 0$ and $f(z)=r(z)\equiv r(x)$. Moreover, it is impractical to forge false proofs: this requires to find a polynomial $g(x)$ which has the same commitment as $f(x)$, i.e. $f((x)-g(x))(\tau)=0$, which either requires the knowledge of $\tau$ or to try to make the difference zero in as most places as possible in the hope to cover $\tau$. In the latter case, this is highly unlikely, as the probability to find a zero is already

$$\text{P}[f(x)-g(x))(s)=0 | s \gets_R\mathbb{F}_r]\leq d/|\mathbb{F}_r|$$

thanks to the Schwartz-Zippel lemma in the univariate case. In our case, the largest degree is $2^{21}$ and the cardinal of the scalar field is $|\mathbb{F}_r|\approx 2^{255}$ so the probability to find a zero is $1/2^{234}$.

## Bound proof on the degree of committed polynomials
Its purpose is to make sure that we added enough redundancy in our erasure code so that the output of the decoding function is correct, and to obtain a bound on the size of the underlying byte sequence.

:::info
Prove that the degree of a committed polynomial is $\leq d$

Public input: $\{g^{\alpha^i}\in\mathbb{G} : i = 0,\dots,n \}$, $\mathcal{C}\in\mathbb{G}$, $d\in\mathbb{N}$.

Prover's private input: $f(x)\in\mathbb{Z}_p[x]_{\leq d}$ such that $\mathcal{C}=g^{f(\alpha)}$.

P1: Compute $f_d(x)={f(x) x^{n-d}}$ such that $\deg f_d \leq n$ and send $\mathcal{C}_d=g^{f_d(\alpha)}$ to V.

V2: Check if $e(\mathcal{C}, g^{\alpha^{n-d}}) = e(\mathcal{C}_d, g)$.
:::


:::warning
We don't check that P knows the polynomial $f$. The protocol below additionally ensures this.
:::

The following protocol besides is given by https://uwspace.uwaterloo.ca/handle/10012/8621 (appendix C).


:::info
$\text{PK}\{ f\in\mathbb{Z}_p[x]_{> 0}: \mathcal{C}=g^{f(\alpha)}\wedge \deg f\leq d\}$

Public input: $\{g^{\alpha^i}\in\mathbb{G} : i = 0,\dots,n \}$, $\mathcal{C}\in\mathbb{G}$, $d\in\mathbb{N}$.

Prover's private input: $f(x)\in\mathbb{Z}_p[x]_{\leq d}$ such that $\mathcal{C}=g^{f(\alpha)}$.

 V1: Send  $i\in\mathbb{Z}_p$ sampled randomly and uniformly to P.

 P2:  Compute $f_d(x)={f(x) x^{n-d}}$ and $w_i=g^{\frac{f(\alpha)-f(i)}{\alpha-i}}$. Sample randomly and uniformly $r,s_1,s_2\in\mathbb{Z}_p^{*}$. Send $(A_1,A_2)=(w_i^{r^{-1}}, e(A_1,g^{\alpha-i})e(g,g)^{s_2})$ and $\mathcal{C}_d=g^{f_d(\alpha)}$ to V.

 V3: Send $c\in\mathbb{Z}_p$ sampled randomly and uniformly  to P.

 P4: Send $(v_1,v_2)=(s_1-r c,s_2-f(i) c)$ to V.

 V5: Check if $A_2 = e(A_1^{v_1},g^{\alpha-i})e(g,g)^{v_2}e(g^{f(\alpha)},g)$ and $e(\mathcal{C}, g^{\alpha^{n-d}}) = e(\mathcal{C}_d, g)$.
:::


We obtain a non-interactive proof via the Fiat-Shamir heuristic (using a collision and preimage-resistant hash function $\mathcal{H}:\{0,1\}^* \to \mathbb{Z}_p$):

:::info
$\text{PK}\{ f: \mathcal{C}=g^{f(\alpha)}\wedge \deg f\leq d\}$ (non-interactive)

Common input: $\{g^{\alpha^i}\in\mathbb{G} : i = 0,\dots,n \}$, $\mathcal{C}\in\mathbb{G}$, $d\in\mathbb{N}$.

Prover's private input: $f(x)\in\mathbb{Z}_p[x]_{\leq d}$ such that $\mathcal{C}=g^{f(\alpha)}$.

 P1:  Compute $f_d(x)={f(x) x^{n-d}}$, $w_i=g^{\frac{f(\alpha)-f(i)}{\alpha-i}}$, and $i=\mathcal{H}(g,d,\mathcal{C})$.
 Sample randomly and uniformly $r,s_1,s_2\in\mathbb{Z}_p^{*}$.
 Compute $c=\mathcal{H}(i,r,s_1,s_2)$.
Send $(A_1,A_2)=(w_i^{r^{-1}}, e(A_1,g^{\alpha-i})e(g,g)^{s_2})$, $(v_1,v_2)=(s_1-r c,s_2-f(i) c)$, and $\mathcal{C}_d=g^{f_d(\alpha)}$ to V.

 V2: Check if $A_2 = e(A_1^{v_1},g^{\alpha-i})e(g,g)^{v_2}e(g^{f(\alpha)},g)$ and $e(\mathcal{C}, g^{\alpha^{n-d}}) = e(\mathcal{C}_d, g)$.
:::


## Batch opening

### Multi-reveals
This feature is described in the KZG extended paper under section 3.4 as batch opening https://link.springer.com/chapter/10.1007/978-3-642-17373-8_11 on arbitrary points. The paper https://github.com/khovratovich/Kate/blob/master/Kate_amortized.pdf shows how to commit and verify quickly when the points form cosets of a group of roots of unity.

For $n~|~|\mathbb{F}_r^{\times}|$, let $\omega$ be a primitive $n$-th root of unity. For $l~|~n$, let $\psi=\omega^{n/l}$ be a primitive $l$-th root of unity and $\Psi=\langle \psi \rangle$.

For $i=0,\dots, n/l - 1$, the proof of the evaluations of $f(x)$ at the $l$ points $\omega^i\Psi$ is the Kate commitment to the quotient of the euclidean division of $f(x)$ by the vanishing polynomial $x^l - \omega^{i l}$ whose only roots are $\omega^i\Psi$. In other words, given the euclidean division ${f(x)=(x^l-\omega^{il}) q_i(x)+r_{i}(x)}$, $\deg r(x) < l$, the proof is $\pi_i = [q_i(\tau)]_1$. Opening at one point corresponds to the case $l=1$ where $r_{i}(x)=f(\omega^{i})$.

To verify the proof, we gather the alleged evaluations of $f(x)$ at the points $\omega^i\Psi$. From these possibly correct evaluations, we can construct an alleged remainder $r_{i}(x)$ by computing the inverse DFT on the domain $\omega^i\Psi$, as $r_{i}(x)=f(x)$ on this domain, and as $r_{i}(x)$ is determined by its evaluations at $l$ distinct points. We then check $$ e(c-[r_i(\tau)]_1, g_2) \overset{?}{=} e(\pi, [\tau^l]_2 - [\omega^{i l}]_2). $$

### Multiple multi-reveals
We now wish to reveal not on the domain $\Omega=\langle \omega \rangle$, but on several subdomains: its $n/l>1$ cosets $\omega^i \Psi$ of $l$ elements each. The committed polynomial $f(x)$ has degree $k-1$ where $k$ corresponds to the dimension of the Reed-Solomon code. We present and slightly extend the result from https://link.springer.com/chapter/10.1007/978-3-642-17373-8_11, which assumes the size of the domains and of their cosets to be powers of two.

Computing the proofs for all such cosets would cost $n/l$ euclidean divisions and multi-exponentiations. Even though the euclidean division by $x^l-\omega^{il}$ is linear in the degree of the committed polynomial, as well as the multi-exponentiation thanks to the Pippenger algorithm (See https://cr.yp.to/papers/pippenger.pdf), computing all proofs leads to a complexity $\mathcal{O}(n/l \times k)$. It turns out the proofs for the cosets are related, so all proofs can be computed in time $\mathcal{O}(n/l\ \log_2 (n/l))$.

Again, for $i=0,\dots,n/l-1$, given the euclidean division $f(x)=(x^l-\omega^{il}) q_i(x)+r_i(x)$, $\deg r_i(x) \leq l-1$, the proofs to be computed are $\pi_i ≔ [q_i(\tau)]_1$.


We denote $d=\deg f$, $m$ the next power of 2 of $d+1$, and set $f_m,f_{m-1},\dots,f_{d+1}=0$. For our purposes we further assume $l|m$, $l<m$.

:::info
We don't require $m$ to be a power of two. However $m$ should be of the form $2^i p$ for a small prime $p$, and $l$ should be of the form $2^j p$ for the same small prime $p$ and $j<i$. Thus $m/l$ is a power of two.
:::

The floor designates here the truncated polynomial long division, where terms $x^i$ for $i<0$ are dropped.

Letting $\varphi≔\omega^l$ a primitive $n/l$-th root of unity:

\begin{align*}
q_i(x)&=\frac{f(x)-r_i(x)}{x^l-\omega^{il}}\\
&=\Bigg\lfloor\frac{f(x)-r_i(x)}{x^l-\omega^{il}}\Bigg\rfloor\\
&=\Bigg\lfloor\frac{f(x)}{x^l-\omega^{il}}\Bigg\rfloor \text{ since } \deg r_i < l\\
&=\Bigg\lfloor\sum_{k=0}^\infty \frac{f(x)}{x^{(k+1)l}}\omega^{kil}\Bigg\rfloor\quad\text{formal power series of } 1/(x^l+c)\\
&= \sum_{k=0}^{m/l-1} \Bigg\lfloor \frac{f(x)}{x^{(k+1)l}}\Bigg\rfloor\varphi^{ik}\\
&=\begin{cases}
\sum_{k=0}^{m/l-1}  (f_m x^{m-(k+1)l} + f_{m-1}x^{m-(k+1)l-1} + \dots + f_{(k+1)l+1}x + f_{(k+1)l})\varphi^{ik} & \text{if } d\geq 2l\\[2ex]
f_m x^{m-l}+\dots+ f_{d}x^{d-l}+\dots+f_{l+1}x+f_l&\text{if } l\leq d<2l.
\end{cases}
\end{align*}

:::warning
There is a subtle condition which is not stated in the original paper (but is more apparent with the above derivation) which is $d\geq 2l$. Indeed, if $l\leq d<2l$, then the powers of $\varphi$ are absent of the quotient:
$$q_i(x)=f_l+f_{l+1}x+\dots+f_{d}x^{d-l}.$$
:::

:::info
For this reason, we assume $d\geq 2l$ (thus $m>2l$).
We could support the other case ($l\leq d < 2l$) but it is a bit cumbersome, and is sort of an edge case for which there are too few shards.
:::

Thus,

$$
    \pi_i =[q_i(x)]_1= \sum_{k=0}^{ m/l-1} (f_m[\tau^{m-(k+1)l}] + f_{m-1}[\tau^{m-(k+1)l-1}] %+ f_{m-2}[\tau^{m-kl-2}]
    + \dots + f_{(k+1)l+1}[\tau] + f_{(k+1)l})\varphi^{ik}.
$$

Letting
$$h_{k}≔
    \begin{cases}
            \sum_{j=kl}^{m} f_j[\tau^{j-kl}] &   \text{for } 0\leq k\leq  m/l,\\
            0 &         \text{for }  m/l<k\leq n/l
    \end{cases}
$$
we obtain $\pi_i = \sum_{k=0}^{n/l-1}  h_{k+1}\varphi^{ik}.$

So by definition $\boldsymbol{\pi}=(\pi_0,\dots, \pi_{n/l-1})$ is the $\text{EC-DFT}_{\varphi}$ of the vector $(h_1,\dots, h_{n/l})\in\mathbb{F}^{n/l}$ ($\star$).

Now, let's address the computation of the coefficients of interest $h_{k}$ for $k=1,\dots,n/l$. To this end, https://github.com/khovratovich/Kate/blob/master/Kate_amortized.pdf observe that the computation of the $h_k$'s can be decomposed into the computation of the $l$ "offset" sums:
$\forall j=0,\dots,l-1$,
$$
h_{k,j}=f_{m-j}[\tau^{m-kl-j}]+f_{m-l-j}[\tau^{m-(k+1)l-j}]%+f_{m-2l-j}[\tau^{m-(k+2)l-j}]
+\dots+f_{(m-j)\%l+kl}[\tau^{(m-j)\%l}].$$
So the desired coefficients can then be obtained with $h_k=\sum_{j=0}^{l-1} h_{k,j}$. This decomposition of the calculation allows the $l$ vectors $(h_{1,j}, \dots, h_{\lfloor \frac{m-j}{l} \rfloor, j})$ for $j=0,\dots, l-1$ to be computed with $l$ Toeplitz matrix-vector multiplications:

$$\begin{bmatrix}
h_{1,j} \\
h_{2,j} \\
\vdots \\
h_{\lfloor \frac{m-j}{l} \rfloor - 1, j}\\
h_{\lfloor \frac{m-j}{l}\rfloor, j}
\end{bmatrix}=\begin{bmatrix}
f_{m-j}     & f_{m-l-j} & f_{m-2l-j}   & \dots & f_{(m-j)\%l+l}\\
0      & f_{m-j} & f_{m-l-j}   & \dots & f_{(m-j)\%l +2l}\\
\vdots & \vdots     & \vdots & \ddots & \vdots \\
0 & 0 & 0   & \dots & f_{m-l-j} \\
0 & 0 & 0   & \dots & f_{m-j}
\end{bmatrix}
\begin{bmatrix}
\tau^{m-l-j} \\
\tau^{m-2l-j} \\
\vdots \\
\tau^{(m-j)\%l+l}\\
\tau^{(m-j)\%l}
\end{bmatrix}.$$

We can extend this Toeplitz matrix to form a circulant matrix whose columns are shifted versions of the vector $\boldsymbol{c}=f_{m-j}\ \Vert\ 0^{\lfloor \frac{m-j}{l}\rfloor-1}\ \Vert\ f_{(m-j)\%l+l}\dots f_{m-j-l}$. We can then compute circulant matrix-vector multiplication with the FFT. See this presentation from Kyle Kloster, student at Purdue University: https://www.youtube.com/watch?v=w0peHpfFVpc.

:::warning
The length of the following transforms is $2m/l$, which we assume is a power of two, for the reasons mentioned above. Though we could in some instances allow transforms of different size using the Prime Factor Algorithm as we currently do for FFTs operating on vectors of scalars.
:::


Given the euclidean divisions $m-j = ql+r$, $0\leq r < l$ for $j=0,\dots,l-1$:
1. Compute $l$ EC-FFTs over $\mathbb{G}_1$: $\forall j=0,\dots,l-1,$
$$ \boldsymbol{s}_j=\text{EC-FFT}_{2m/l}(\tau_{m-j-l} \tau_{m-j-2l} \tau_{m-j-3l} \dots \tau_{m-j-ql=r} \ \Vert\ 0^{2m/l - \lfloor \frac{m-j}{l}\rfloor}).$$

:::info
The above calculation can be done once per trusted setup and can thus be cached.
:::


2. Compute $l$ FFTs over $\mathbb{F}_r$: $\forall j=0, \dots, l-1$, with $f_{m}=0$:

$$\boldsymbol{f}_j = \text{FFT}_{2m/l}(f_{m-j} \ \Vert\ 0^{q +2\times pad+1 } \ \Vert\ \underbrace{f_{r+l} f_{r+2l} \dots f_{r+(q-1)l=m-j-l}}_{q-1 \ elements}  \ \Vert\ 0^{2m/l-(2q+2\times pad+1) }).$$

where $q=\lfloor \frac{m-j}{l}\rfloor$ and $pad=2^{log2up(q)}-q$.

3. Then compute $\boldsymbol{h}=(h_k)_{k\in ⟦1, n/l⟧ }$ with circulant matrix-vector multiplication via FFT:
\begin{align*}
    \boldsymbol{h}&= \sum_{j=0}^{l-1} (h_{1,j} \dots h_{\lfloor \frac{m-j}{l} \rfloor, j} \ \Vert\ 0^{2m/l-\lfloor \frac{m-j}{l}\rfloor })\\
    &=\sum_{j=0}^{l-1}\text{EC-IFFT}_{2m/l}(\boldsymbol{f}_j \odot_{\mathbb{G}_1} \boldsymbol{s}_j)\\
    &=\text{EC-IFFT}_{2m/l}\Big(\sum_{j=0}^{l-1} (\boldsymbol{f}_j \odot_{\mathbb{G}_1} \boldsymbol{s}_j)\Big).
\end{align*}




4. The first $n/l$ coefficients is the result of the multiplication by the Toeplitz vector (with a bit of zero padding starting from the $m/l$-th coefficient): let's call this vector $\boldsymbol{h}'$. The $n/l$ KZG proofs are given by $\boldsymbol{\pi}=\text{EC-FFT}_{n/l}(\boldsymbol{h}')$ following the observation ($\star$).

### Complexity of multiple multi-reveals

For the preprocessing part, we count $l$ EC-FFTs on $\mathbb{G}_1$, so the asymptotic complexity of the step is $O(l\times (m/l) \log (m/l))=O(m\ \log(m/l))$.

For the KZG proofs generation part, we count $l$ FFTs on $\mathbb{F}_r$ and two EC-FFTs on $\mathbb{G}_1$: the runtime complexity is $O(l\times T_{\mathbb{F}_r}(m/l) + T_{\mathbb{G}_1}(n/l)+2m\log 256)$, where $T_{\mathbb{F}_r}$ and $T_{\mathbb{G}_1}$ represent the runtime cost of the FFT and EC-FFT. Both have the same complexity, even though the latter hides a bigger constant (log of scalar size in bits, here $\log 256$) due to the elliptic curve scalar multiplication.


Let's recall that $l$ is in our application the length of a shard, $n$ is the length of the erasure code and $m=k$ is the dimension of the erasure code. Calling $s$ the number of shards, we obtain  $l=n/s=\alpha k / s$. The runtime of the precomputation part can be rewritten as $O(k \ \log (s/\alpha))$.
And the computation of the $n/l$ KZG proofs becomes $O(k\ \log (s/\alpha) + \log 256\times (s \ \log\ s + 2k)).$
This explains why the algorithm is more efficient with bigger erasure code redundancies, especially the precomputation part as it performs EC-FFTs.

:::warning
This applies to the proving time for shards:
However, for our purposes the length of a shard $s<<k$, so the bottleneck is the pointwise scalar multiplication in $\mathbb{G}_1$ (the $2k\log256$ term).
:::


# Formalization of the cryptography for the DAL

Relations between the different data types:
```
                            RAW BYTES
                              │
                              │ serialize to a sequence of d scalar elements
                              │
                              ▼
                     ~~~~~▶ DATA
                     │        │
  evaluate           │        │ interpolate (domain of size d+1)
(domain of size d+1) │        │
                     │        ▼
                     ~~~~~~ POLY ~~~~~~~~~~~~~~~~~~~~~▶ C
                              │            commit
                              │
                              │ evaluate (domain of size n>d+1)
                              │
                              ▼
                            SHARDS
                              │
                              │ interpolate (domain of size d+1)
                              │
                              ▼
                            POLY
```

### Syntax

(Aside: we're mixing types with sets)
#### Types
natural integers $N$, elements from prime field $X$, evaluations $Y$, polynomials with coefficients in the prime field $P$, proofs $\Pi$, commitments $C$, booleans $B=\{0,1\}$, errors $\bot$

#### Functions
+ $\deg(P):\textit{N}$
+ $\text{eval}(P, X): Y$
+ $\text{commit}(P):C$
+ $\text{evaluate}(P,X^{d+1}):Y^{d+1}$ (RS encoding)
+ $\text{interpolate}(X^{d+1},Y^{d+1}):P$ (RS decoding)
+ $\text{proveDegree}(P,N):\Pi|\bot$
+ $\text{verifyDegree}(C,N,\Pi):B$
+ $\text{proveEval}(P,X,Y):\Pi| \bot$
+ $\text{verifyEval}(X,Y,C,\Pi):B$

### Specifications
When variables are not quantified it defaults to the universal quantifier.
1. $\text{verifyEval}(x,y,c,\pi)=1 \implies \exists p, \text{commit}(p)=c \wedge \pi=\text{proveEval}(p,x,y)$
2. $\text{proveEval}(x,y,p)\in\Pi \iff \text{eval}(p,x)=y$
3. $\text{verifyDegree}(c,d,\pi)=1 \implies \exists p, \text{commit}(p)=c \wedge \deg(p)\leq d \wedge \pi=\text{proveDegree}(p,d)$
4. $\text{interpolate}((x_0,\dots,x_d),(y_0,\dots,y_d))=p\implies \deg p\leq d \wedge (\bigwedge_{i=0}^d \text{eval}(p,x_i)=y_i)$
5. $\deg p\leq d, \deg \tilde p \leq d, \forall (x_0,\dots,x_d)\in X^{d+1}, \forall i\in [|0,d|], \text{eval}(p,x_i)=\text{eval}(\tilde p, x_i)\implies p=\tilde p$
6. $p,\tilde p$, $\text{commit}(p)=\text{commit}(\tilde p) \implies p=\tilde p$ **(technically false, but it is computationally infeasible to exhibit two distinct polynomials whose commitments are equal)**

### Properties
Prop 1. (RS decoding succeeds): $\forall c\in C$, $\forall (x_0,\dots,x_d)\in X^{d+1}$, $\forall (y_0,\dots,y_d)\in Y^{d+1}$, $\forall(\pi_0,\dots,\pi_d)\in\Pi^{d+1}$, $\forall \pi\in\Pi$,

$$((\forall i\in[|0,d|], \text{verifyEval}(x_i,y_i,c,\pi_i)=1)\wedge \text{verifyDegree}(c,d,\pi)=1)\\\implies (\exists! p, \text{commit}(p)=c \wedge (\bigwedge_{i=0}^d\pi_i=\text{proveEval}(p,x_i,y_i))\\\wedge\text{interpolate}((x_0,\dots,x_d),(y_0,\dots,y_d))=p).$$

Proof: Apply 1. for $i=0,\dots,d$ and 3. Apply 6 (uniqueness of $p$ such that $\text{commit}(p)=c$). Introduce $\text{interpolate}((x_0,\dots,x_d),(y_0,\dots,y_d))=\tilde p$. Apply 4.

State of the proof:
- $\exists! p,  \text{commit}(p)\wedge (\bigwedge_{i=0}^d\pi_i=\text{proveEval}(p,x_i,y_i))\wedge \deg p \leq d$
- $\text{interpolate}((x_0,\dots,x_d),(y_0,\dots,y_d))=\tilde p \wedge \deg \tilde p\leq d \wedge (\bigwedge_{i=0}^d \text{eval}(\tilde p,x_i)=y_i)$

Apply 2. for $i=0,\dots,d$ (adds $\bigwedge_{i=0}^d\text{eval}(p,x_i)=y_i$ into the context)

Apply 5. (conclusion: $\tilde p = p$)

---

Prop 2. (If the verification of a page succeeds, the underlying polynomial is a preimage of the commitment, and this polynomial is unique):

$\forall c\in C$, $\forall (y_0,\dots,y_d)\in Y^{d+1}$, $\forall(\pi_0,\dots,\pi_d)\in\Pi^{d+1}$,

$$(\forall i\in[|0,d|], \text{verifyEval}(x_i,y_i,c,\pi_i)=1)\\\implies
\exists! p, \text{commit}(p)=c \wedge (\bigwedge_{i=0}^d\pi_i=\text{proveEval}(p,x_i,y_i))$$

Proof: Apply 1. for $i=0,\dots,d$. Apply 6 (uniqueness of $p$ such that $\text{commit}(p)=c$).

# Implementation details

## How many bytes can we put into a scalar field element?
Since the cardinal of the scalar field fits in $255$ bytes but is slightly less than $2^{255}$, we parse byte sequences by chunks of 31 bytes. This means that a valid encoding is made of elements of scalar which are strictly less than $2^{248}$. For now, there are no checks as we simply truncate scalar elements to $31$ bytes when converting polynomials back to byte sequences.

## Serialize a byte sequence to a scalar array
**Is it injective?** (with fixed DAL parameters such as `slot_size`, `page_size`, etc.)
**Yes!**

Here is the code that does the conversion
```ocaml
let polynomial_from_bytes' (t : t) slot =
    if Bytes.length slot <> t.slot_size then
      Error
        (`Slot_wrong_size
          (Printf.sprintf "message must be %d bytes long" t.slot_size))
    else
      let offset = ref 0 in
      let res = Array.init t.k (fun _ -> Scalar.(copy zero)) in
      for page = 0 to t.pages_per_slot - 1 do
        for elt = 0 to t.page_length - 1 do
          (* [!offset >= t.slot_size] because we don't want to read past
             the buffer [slot] bounds. *)
          if !offset >= t.slot_size then ()
          else if elt = t.page_length - 1 then (
            let dst = Bytes.create t.remaining_bytes in
            Bytes.blit slot !offset dst 0 t.remaining_bytes ;
            offset := !offset + t.remaining_bytes ;
            res.((elt * t.pages_per_slot) + page) <- Scalar.of_bytes_exn dst)
          else
            let dst = Bytes.create scalar_bytes_amount in
            Bytes.blit slot !offset dst 0 scalar_bytes_amount ;
            offset := !offset + scalar_bytes_amount ;
            res.((elt * t.pages_per_slot) + page) <- Scalar.of_bytes_exn dst
        done
      done ;
      Ok res


let polynomial_from_slot t slot =
    let open Result_syntax in
    let* data = polynomial_from_bytes' t slot in
    Ok (Evaluations.interpolation_fft2 t.domain_k data)
```
It first expects the length of the byte sequence to equal the slot size. This can be achieved by adding some padding with null bytes to the byte sequence if the length is strictly less than the slot size, or truncate it if the length is strictly greater than the slot size.

A slot is subdivided into contiguous segments, called pages. The length of a page divides the slot size.

Once the above precondition is verified, we parse the slot page by page. We store into elements portions of up to `scalar_bytes_amount` bytes from a page. A permutation (so a bijection) is then applied to the elements from a page. The code applies the permutation to a scalar element just after it is read from the page, but it is easier to picture it as two successive steps:
1. a serialization phase where you represent pages by sequences of scalar elements, which is injective: if two outputs for two slots are equal, then the slots are equal since we're just splitting a page into chunks of `scalar_bytes_amount` bytes and a last one of `t.remaining_bytes` bytes
2. then apply the permutation (`res.((elt * t.pages_per_slot) + page) <- Scalar.of_bytes_exn dst`)

The resulting vector is then interpolated. Polynomial interpolation is a linear bijection (as a ring isomorphism) between $k$-tuples of scalar elements and polynomials with coefficients in the scalar field of degree $<k$.

Thus `polynomial_from_slot` is an injection from slots to polynomials (as composition preserves injectivity).
