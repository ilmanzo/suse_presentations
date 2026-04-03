fn is_prime(n: u64) -> bool {
    let sqrt_n = (n as f64).sqrt() as u64;
    for j in (3..=sqrt_n).step_by(2) {
        if n % j == 0 {
            return false;
        }
    }
    true
}

fn main() {
    let mut n = 2;
    let mut i = 3;

    while n < 1_000_000 {
        i += 2;
        if is_prime(i) {
            n += 1;
        }
    }
    println!("Mth Prime is {}", i);
}
