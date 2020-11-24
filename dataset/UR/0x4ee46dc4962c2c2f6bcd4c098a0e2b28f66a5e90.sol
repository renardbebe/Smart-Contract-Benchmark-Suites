 

pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;


contract IHumanity {
    function mint(address account, uint256 value) public;
    function totalSupply() public view returns (uint256);
}


 
contract HumanityRegistry {

    mapping (address => bool) public humans;

    IHumanity public humanity;
    address public governance;

    constructor(IHumanity _humanity, address _governance) public {
        humanity = _humanity;
        governance = _governance;
    }

    function add(address who) public {
        require(msg.sender == governance, "HumanityRegistry::add: Only governance can add an identity");
        require(humans[who] == false, "HumanityRegistry::add: Address is already on the registry");

        _reward(who);
        humans[who] = true;
    }

    function remove(address who) public {
        require(
            msg.sender == governance || msg.sender == who,
            "HumanityRegistry::remove: Only governance or the identity owner can remove an identity"
        );
        delete humans[who];
    }

    function isHuman(address who) public view returns (bool) {
        return humans[who];
    }

    function _reward(address who) internal {
        uint totalSupply = humanity.totalSupply();

        if (totalSupply < 28000000e18) {
            humanity.mint(who, 30000e18);  
        } else if (totalSupply < 46000000e18) {
            humanity.mint(who, 20000e18);  
        } else if (totalSupply < 100000000e18) {
            humanity.mint(who, 6000e18);  
        }

    }

}