 

import "./MintableToken.sol";
import "./CappedToken.sol";

contract Blank is CappedToken {
 
    string public name = "BLANK";
    string public symbol = "BLK";
    uint8 public decimals = 2;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}




