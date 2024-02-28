module ut.arrays;


import ut;


@("index.1")
unittest {
    enum source = "
        fn idx(a: [u32]): u32 => a[1]
        fn main(x: u32): u32 => idx([2, 3, 4])
    ";
    auto main = mainFunc(source);
    main(42).should == 3;
}

@("index.2")
unittest {
    enum source = "
        fn idx(a: [u32]): u32 => a[2]
        fn main(x: u32): u32 => idx([2, 3, 4])
    ";
    auto main = mainFunc(source);
    main(42).should == 4;
}

@("two")
unittest {
    enum source = "
        fn idx(a: [u32], b: [u32]): u32 => b[0]
        fn main(x: u32): u32 => idx([2, 3, 4], [5, 6, 7])
    ";
    auto main = mainFunc(source);
    main(42).should == 5;

}
