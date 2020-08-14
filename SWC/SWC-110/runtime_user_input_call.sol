/*
 * @source: ChainSecurity
 * @author: Anton Permenev
 * @Labeled: [11]
 */
pragma solidity ^0.4.19;

contract RuntimeUserInputCall{

    function check(address b){
        assert(B(b).foo() == 10);
    }

}

contract B{
    function foo() returns(uint);
}
