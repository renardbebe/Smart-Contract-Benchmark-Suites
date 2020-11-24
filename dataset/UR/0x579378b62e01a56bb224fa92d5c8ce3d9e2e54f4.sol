 

 

 
 
 


pragma solidity 0.5.13;

contract ReverseRegistrar {
    function claim(address owner) public returns (bytes32 node);
}

contract OrchidCurator {
    function good(address, bytes calldata) external view returns (uint128);
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

    struct Entry {
        uint128 adjust_;
        bool valid_;
    }

    mapping (address => Entry) private entries_;

    function kill(address provider) external {
        require(msg.sender == owner_);
        delete entries_[provider];
    }

    function tend(address provider, uint128 adjust) public {
        require(msg.sender == owner_);
        Entry storage entry = entries_[provider];
        entry.adjust_ = adjust;
        entry.valid_ = true;
    }

    function list(address provider) external {
        return tend(provider, uint128(-1));
    }

    function good(address provider, bytes calldata) external view returns (uint128) {
        Entry storage entry = entries_[provider];
        require(entry.valid_);
        return entry.adjust_;
    }
}