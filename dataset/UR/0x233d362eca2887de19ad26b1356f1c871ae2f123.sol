 

pragma solidity ^0.5.10;

contract MolochLike {
    function updateDelegateKey(address) external;
    function submitVote(uint256, uint8) external;
    function submitProposal(address, uint256, uint256, string calldata) external;
    function processProposal(uint256) external;
    function getProposalQueueLength() external view returns (uint256);
    function getMemberProposalVote(address, uint256) external view returns (uint256);
    function proposalDeposit() external view returns (uint256);
    function periodDuration() external view returns (uint256);
    function approvedToken() external view returns (address);
}

contract GemLike {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract WethLike is GemLike {
    function deposit() external payable;
}

contract SelloutDao {
    address    public owner;
    MolochLike public dao;
    GemLike    public gem;
    address    public hat;
    bool       public sold;
    uint256    public prop;
    bool       public voted;

    modifier auth() {
        require(msg.sender == owner, "nope");
        _;
    }

    modifier only_hat() {
        require(msg.sender == hat, "nope");
        _;
    }

    constructor(MolochLike dao_) public {
        owner = msg.sender;
        dao = dao_;
        gem = GemLike(dao.approvedToken());
    }

    function () external payable {
        buy();
    }

    function buy() public payable {
        require(!sold, "already sold");
        require(msg.value >= 0.5 ether, "need to send at least 0.5 eth");
        sold = true;
        hat = msg.sender;
    }

    function make(address who, uint256 tribute, uint256 shares, string calldata text) external only_hat {
        require(prop == 0, "can only create one proposal");
        gem.approve(address(dao), dao.proposalDeposit());
        dao.submitProposal(who, tribute, shares, text);
        prop = dao.getProposalQueueLength() - 1;
    }

    function vote(uint8 val) external only_hat {
        dao.submitVote(prop, val);
    }

    function take() external auth {
        msg.sender.transfer(address(this).balance);
        gem.transfer(msg.sender, gem.balanceOf(address(this)));
    }
}