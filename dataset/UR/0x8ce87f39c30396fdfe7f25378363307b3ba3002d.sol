 

pragma solidity >=0.5.0 <0.6.0;

contract Bankshot {
   address payable public owner;
   uint256 private vigBalance;
   uint256 public ethVig;
   uint256 public minEthDeposit;
   uint256 public maxEthDeposit;
   bool public areSubmissionsLocked;

   struct Submission {
       bytes32 sHash;
       uint256 deposit;
       bool isRevealed;
   }

   mapping(address => Submission[]) submissions;

   event Publication(
       address indexed user,
       uint256 indexed subID,
       uint256 indexed date
   );

   event Revelation(
       address indexed user,
       uint256 indexed subID,
       uint256 indexed date,
       bytes revelation
   );

    constructor(uint256 _ethVig,
                uint256 _minEthDeposit) public {

        owner = msg.sender;
        ethVig = _ethVig;
        minEthDeposit = _minEthDeposit;
        maxEthDeposit = 1 ether;
        areSubmissionsLocked = false;
    }

    function minEthPayable() public view returns (uint256) {
        return ethVig + minEthDeposit;
    }

    function setEthVig(uint256 _newVig) public onlyOwner {
        ethVig = _newVig;
    }

    function setMinEthDeposit(uint256 _newMinEthDeposit) public onlyOwner {
        minEthDeposit = _newMinEthDeposit;
    }

    function setMaxEthDeposit(uint256 _newMaxEthDeposit) public onlyOwner {
        maxEthDeposit = _newMaxEthDeposit;
    }

    function withdrawVig(uint256 _amount) public onlyOwner {
        require(_amount <= vigBalance, "WITHDRAW_LIMIT");

        vigBalance -= _amount;
        owner.transfer(_amount);
    }

    function lockSubmissions() public onlyOwner {
        areSubmissionsLocked = true;
    }

    function submitHash(bytes32 _hash) public payable paysMin paysUnderMax isUnlocked {
        uint256 deposit = msg.value - ethVig;
        submissions[msg.sender].push(Submission({ sHash: _hash, deposit: deposit, isRevealed: false}));
        vigBalance += (msg.value - deposit);

        emit Publication(msg.sender, submissions[msg.sender].length - 1, block.timestamp);  
    }

    function submissionsForAddress(address _address) public view returns(bytes32[] memory hashes, uint256[] memory deposits) {
        Submission[] storage subs = submissions[_address];

        hashes = new bytes32[](subs.length);
        deposits = new uint256[](subs.length);

        for (uint i = 0; i < subs.length; i++) {
            hashes[i] = subs[i].sHash;
            deposits[i] = subs[i].deposit;
        }

        return (hashes, deposits);
    }

    function revealSubmission(uint _subID, bytes memory _revelation) public {
        Submission storage sub = submissions[msg.sender][_subID];
        require(!sub.isRevealed, "ALREADY_REVEALED");

        bytes32 revealHash = keccak256(abi.encodePacked(_revelation));
        require(revealHash == sub.sHash, "INVALID_REVEAL");

        sub.isRevealed = true;
        emit Revelation(msg.sender, _subID, block.timestamp, _revelation);

        msg.sender.transfer(sub.deposit);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier paysMin() {
        require(msg.value >= minEthPayable(), 'INSUFFICIENT_FUNDS');
        _;
    }

    modifier paysUnderMax() {
        uint256 deposit = msg.value - ethVig;
        require(deposit <= maxEthDeposit, 'OVERSIZE_DEPOSIT');
        _;
    }

    modifier isUnlocked() {
        require(!areSubmissionsLocked, 'SUBS_LOCKED');
        _;
    }
}