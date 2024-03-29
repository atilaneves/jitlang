module ut.ints;


import ut;


@("twice")
unittest {
    enum source = "
        fn twice(x: u32): u32 => x * 2
        fn main(x: u32): u32 => twice(x)
    ";
    auto main = mainFunc(source);
    main(2).should == 4;
    main(3).should == 6;
}

@("thrice")
unittest {
    enum source = "
        fn thrice(x: u32): u32 => x * 3
        fn main(x: u32): u32 => thrice(x)
    ";
    auto main = mainFunc(source);
    main(2).should == 6;
    main(3).should == 9;
}

@("params")
unittest {
    enum source = "
        fn snd(x: u32, y: u32): u32 => y
        fn main(x: u32): u32 => snd(x, x * 2)
    ";
    auto main = mainFunc(source);
    main(2).should == 4;
    main(3).should == 6;
}
