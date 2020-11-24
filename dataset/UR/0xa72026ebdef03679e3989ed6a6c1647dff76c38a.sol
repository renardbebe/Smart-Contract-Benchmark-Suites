 

pragma solidity ^0.5.10;

contract EmpowBonus {
    
    event Bonus(address indexed _address, uint32 indexed dapp_id, uint256 _time, uint256 _bonus_amount, uint256 _pay_amount);
    
    struct BonusHistory {
        address user;
        uint32 dapp_id;
        uint256 time;
        uint256 bonus_amount;
        uint256 pay_amount;
    }
    
    mapping (address => uint256) public countBonus;
    mapping (address => mapping (uint256 => BonusHistory)) public bonusHistories;
    
    address payable owner;
    
    modifier onlyOwner () {
        require(msg.sender == owner, "owner require");
        _;
    }
    
    constructor ()
        public
    {
        owner = msg.sender;
    }
    
    function bonus (uint32 _dapp_id, uint256 _bonus_amount)
        public
        payable
        returns(bool)
    {
        require(msg.value > 0);
        
        countBonus[msg.sender]++;
        
        uint256 currentTime = block.timestamp;
        
        emit Bonus(msg.sender, _dapp_id, currentTime, _bonus_amount, msg.value);
        saveHistory(msg.sender, _dapp_id, currentTime, _bonus_amount, msg.value);
        
        return true;
    }
    
    function saveHistory (address _address, uint32 _dapp_id, uint256 _time, uint256 _bonus_amount, uint256 _pay_amount)
        private
        returns(bool)
    {
        bonusHistories[msg.sender][countBonus[_address]].user = _address;
        bonusHistories[msg.sender][countBonus[_address]].dapp_id = _dapp_id;
        bonusHistories[msg.sender][countBonus[_address]].time = _time;
        bonusHistories[msg.sender][countBonus[_address]].bonus_amount = _bonus_amount;
        bonusHistories[msg.sender][countBonus[_address]].pay_amount = _pay_amount;
        return true;
    }
    
    function withdraw (uint256 _amount) 
        public
        onlyOwner
        returns (bool)
    {
        owner.transfer(_amount);
        return true;
    }
    
}