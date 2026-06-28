# Skolem Propagator — Bose-Hubbard

Skolem-sequence-based propagators for the Bose-Hubbard model, with QuSpin used
as a reference for validation.

## Numerical method

This repository implements the propagator introduced in
[arXiv:2603.25639](https://arxiv.org/html/2603.25639v1).

The key idea is the **Skolem polynomial**, a bijection that maps a Fock state
`(n₁, …, n_K)` (site occupations of `N` bosons on `K` sites) onto a single
integer index. It is constructed so that states connected by a nearest-neighbor
hop differ in index by `±1`, and so that states of equal total particle number
form contiguous, gapless blocks. As a consequence, the hopping (kinetic) part of
the Bose-Hubbard Hamiltonian for a single bond becomes **block-tridiagonal** in
this ordering, with the on-site interaction sitting on the diagonal.

The time evolution is then built with a **split-operator** scheme:

1. **Single-bond exponential.** The tridiagonal blocks are diagonalized
   independently with `eigh_tridiagonal`, giving the exact bond propagator
   `exp(-i·dt·H_bond)` (an $O(D^2)$-style cost instead of $O(D^3)$ for a dense $D \times D$ matrix).
   Note that cost can be brought down to $O(D \log D)$ if the algorithm
   [Coakley, Rokhlin *Appl. Comp. Harm. Anal.* **34**, 379 (2012)](https://doi.org/10.1016/j.acha.2012.06.003)
   is used.
3. **Skolem shift.** A relabeling of the basis — implemented as the cheap
   index permutation `psi[indx]` rather than a matrix product — cyclically
   rotates the sites so that *every* bond can reuse the *same* tridiagonal
   exponential.
4. **Sweep.** Applying the exponential interleaved with the shift `K` times
   propagates the full ring (periodic boundary conditions); a slightly modified
   sweep with an extra on-site phase at the ends handles open boundaries.

This first-order Trotter scheme is in
[skolem_propagator_bose_hubbard.py](skolem_propagator_bose_hubbard.py). A
second-order (symmetrized, `τ/2` forward/backward) variant is in
[second_ord_skolem_propagator_bose_hubbard.py](second_ord_skolem_propagator_bose_hubbard.py).
The Skolem map and its inverse live in [skolem_util.py](skolem_util.py).

Because the propagator only ever stores tridiagonal blocks and applies them
via index permutations, it is unitary to machine precision and uses far less
memory than the dense Hamiltonian, letting it reach larger basis sizes than
conventional approaches.

## Setup

The project depends on [QuSpin](https://quspin.github.io/QuSpin/). Run the setup
script to create a local virtual environment and register a Jupyter kernel:

```bash
./setup.sh
```

This will:

1. Create a virtual environment in `./.venv`
2. Install the pinned dependencies from `requirements.txt`
   (QuSpin, Jupyter, matplotlib, plus numpy/scipy/numba as transitive deps)
3. Register a Jupyter kernel named **"Python (.venv SkolemPropagator)"**
4. Verify that QuSpin imports correctly

### Requirements

- **Python 3.12** — QuSpin 1.0.1 only ships PyPI wheels for CPython 3.12.
  If `python3` on your system is a different version, point the script at a
  3.12 interpreter:

  ```bash
  PYTHON=python3.12 ./setup.sh
  ```

## Usage

**From the terminal:**

```bash
source .venv/bin/activate
python skolem_propagator_bose_hubbard.py
```

**In the notebooks** select the **"Python (.venv SkolemPropagator)"** kernel,
then Run All:

- [demo_skolem_vs_quspin.ipynb](demo_skolem_vs_quspin.ipynb) — validates the
  first-order Skolem propagator against QuSpin's exact Bose-Hubbard evolution
  (here `N = 100` bosons on `K = 4` sites), comparing accuracy and runtime for
  both periodic and open boundary conditions.
- [demo_second_ord_skolem_propagator.ipynb](demo_second_ord_skolem_propagator.ipynb)
  — compares the first- and second-order Skolem propagators against an exact
  reference, showing the improved convergence of the second-order scheme as the
  time step is varied (the source of the `*_1st_2nd*.png` plots).
