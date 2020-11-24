/*
 * @source: ChainSecurity
 * @author: Anton Permenev
 * @Labeled: [13]
 */

pragma solidity ^0.4.25;

contract ConstructorCreate{
    B b = new B();

    function check(){
        assert(b.foo() == 10);
    }

}

contract B{

    function foo() returns(uint){
        return 11;
    }
}
