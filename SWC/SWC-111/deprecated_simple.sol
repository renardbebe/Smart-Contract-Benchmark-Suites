/* @Labeled: [8, 10, 11, 13, 16, 19, 21, 23, 25] */
pragma solidity ^0.4.24;

contract DeprecatedSimple {

    // Do everything that's deprecated, then commit suicide.

    function useDeprecated() public constant {

        bytes32 blockhash = block.blockhash(0);
        bytes32 hashofhash = sha3(blockhash);

        uint gas = msg.gas;

        if (gas == 0) {
            throw;
        }

        address(this).callcode();

        var a = [1,2,3];

        var (x, y, z) = (false, "test", 0);

        suicide(address(0));
    }

    function () public {}

}
