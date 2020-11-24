 

pragma solidity 0.4.18;


contract Owned {
     
    address public owner;

     
    function Owned() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}


 
 
contract ERC20Interface {
     
    uint256 public totalSupply;  

     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _amount) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);

     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    event TransferEvent(address indexed _from, address indexed _to, uint256 _amount);

     
    event ApprovalEvent(address indexed _owner, address indexed _spender, uint256 _amount);
}


 
contract EngravedToken is ERC20Interface, Owned {
    string public constant symbol = "EGR";
    string public constant name = "Engraved Token";
    uint8 public constant decimals = 3;

     
    bool public incentiveDistributionStarted = false;
    uint256 public incentiveDistributionDate = 0;
    uint256 public incentiveDistributionRound = 1;
    uint256 public incentiveDistributionMaxRounds = 4;
    uint256 public incentiveDistributionInterval = 1 years;
    uint256 public incentiveDistributionRoundDenominator = 2;

     
    struct Incentive {
        address recipient;
        uint8 percentage;
    }

    Incentive[] public incentives;

     
    bool public locked;

     
    mapping(address => uint256) internal balances;

     
    mapping(address => mapping (address => uint256)) internal allowed;

     
    function EngravedToken() public {
        owner = msg.sender;
        balances[owner] = 0;
        totalSupply = 0;
        locked = true;

        incentives.push(Incentive(0xCA73c8705cbc5942f42Ad39bC7EAeCA8228894BB, 5));  
        incentives.push(Incentive(0xd721f5c14a4AF2625AF1E1E107Cc148C8660BA72, 5));  
    }

     
    function() public {
        assert(false);
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(!locked);
        require(balances[msg.sender] >= _amount);
        require(_amount > 0);
        assert(balances[_to] + _amount > balances[_to]);

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        TransferEvent(msg.sender, _to, _amount);
        return true;
    }

     
    function transferFrom (
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        require(!locked);
        require(balances[_from] >= _amount);
        require(allowed[_from][msg.sender] >= _amount);
        require(_amount > 0);
        assert(balances[_to] + _amount > balances[_to]);

        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        TransferEvent(_from, _to, _amount);
        return true;
    }

     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(!locked);

         
        allowed[msg.sender][_spender] = _amount;

         
        ApprovalEvent(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (
        uint256 remaining
    ) {
        return allowed[_owner][_spender];
    }

     
    function startIncentiveDistribution() public onlyOwner returns (bool success) {
        if (!incentiveDistributionStarted) {
            incentiveDistributionDate = now;
            incentiveDistributionStarted = true;
        }

        return incentiveDistributionStarted;
    }

     
    function withdrawIncentives() public {
         
        require(incentiveDistributionStarted);

         
        require(incentiveDistributionRound < incentiveDistributionMaxRounds);

         
        require(now > incentiveDistributionDate);

        uint256 totalSupplyToDate = totalSupply;
        uint256 denominator = 1;

         
        if (incentiveDistributionRound > 1) {
            denominator = incentiveDistributionRoundDenominator**(incentiveDistributionRound - 1);
        }

        for (uint256 i = 0; i < incentives.length; i++) {

            uint256 amount = totalSupplyToDate * incentives[i].percentage / 10**2 / denominator;
            address recipient = incentives[i].recipient;

             
            balances[recipient] += amount;
            totalSupply += amount;

             
            TransferEvent(0, this, amount);
            TransferEvent(this, recipient, amount);
        }

         
        incentiveDistributionDate = now + incentiveDistributionInterval;
        incentiveDistributionRound++;
    }

     
    function unlock() public onlyOwner returns (bool success) {
        locked = false;
        return true;
    }

     
    function issue(address _recipient, uint256 _amount) public onlyOwner returns (bool success) {
         
        require(_amount >= 0);

         
        balances[_recipient] += _amount;
        totalSupply += _amount;

         
        TransferEvent(0, owner, _amount);
        TransferEvent(owner, _recipient, _amount);

        return true;
    }

}