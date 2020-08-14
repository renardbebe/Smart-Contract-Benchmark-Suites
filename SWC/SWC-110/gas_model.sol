/*
 * @source: ChainSecurity
 * @author: Anton Permenev
 * @Labeled: [14]
 */
pragma solidity ^0.4.21;

contract GasModel{
    uint x = 100;
    function check(){
        uint a = gasleft();
        x = x + 1;
        uint b = gasleft();
        assert(b > a);
    }
}
