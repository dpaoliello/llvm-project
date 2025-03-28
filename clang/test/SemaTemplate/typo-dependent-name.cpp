// RUN: %clang_cc1 -std=c++14 -fsyntax-only -verify %s

using nullptr_t = decltype(nullptr);

template<typename T>
struct Base {
  T inner;
};

int z;

template<typename T>
struct X : Base<T> {
  static int z;

  template<int U>
  struct Inner {
  };

  bool f(T other) {
    // A pair of comparisons; 'inner' is a dependent name so can't be assumed
    // to be a template.
    return this->inner < other > ::z; // expected-error {{chained comparison 'X < Y > Z' does not behave the same as a mathematical expression}}
  }
};

void use_x(X<int> x) { x.f(0); } // expected-note {{requested here}}

template<typename T>
struct Y {
  static int z;

  template<int U>
  struct Inner; // expected-note {{declared here}}

  bool f(T other) {
    // We can determine that 'inner' does not exist at parse time, so can
    // perform typo correction in this case.
    return this->inner<other>::z; // expected-error {{no template named 'inner' in 'Y<T>'; did you mean 'Inner'?}}
  }
};

template<typename T>
template<int U>
struct Y<T>::Inner : Y { };

struct Q { constexpr operator int() { return 0; } };
void use_y(Y<Q> x) { x.f(Q()); }
