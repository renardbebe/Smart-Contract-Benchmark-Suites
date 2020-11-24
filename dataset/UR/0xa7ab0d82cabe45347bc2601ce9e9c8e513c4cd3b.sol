 

 

 
 
 


pragma solidity 0.5.13;

contract ReverseRegistrar {
    function claim(address owner) public returns (bytes32 node);
}

contract OrchidCurator {
    function good(address, bytes calldata) external view returns (bool);
}

contract OrchidList is OrchidCurator {
    ReverseRegistrar constant private ens_ = ReverseRegistrar(0x9062C0A6Dbd6108336BcBe4593a3D1cE05512069);

    address private owner_;

    constructor() public {
        ens_.claim(msg.sender);
        owner_ = msg.sender;
    }

    function hand(address owner) external {
        require(msg.sender == owner_);
        owner_ = owner;
    }

    struct Provider {
        bool good_;
    }

    mapping (address => Provider) private providers_;

    function list(address provider, bool good) external {
        require(msg.sender == owner_);
        providers_[provider].good_ = good;
    }

    function good(address provider, bytes calldata) external view returns (bool) {
        return providers_[provider].good_;
    }
}