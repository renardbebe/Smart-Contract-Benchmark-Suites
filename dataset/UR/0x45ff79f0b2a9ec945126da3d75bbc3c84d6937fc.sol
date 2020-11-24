 

pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract OysterPearl {
     
    string public name = "Oyster Pearl";
    string public symbol = "TPRL";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public funds = 0;
    address public owner;
    bool public saleClosed = true;
    bool public ownerLock = false;
    uint256 public claimAmount;
    uint256 public payAmount;
    uint256 public feeAmount;
    uint256 public epoch;
    uint256 public retentionMax;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public buried;
    mapping (address => uint256) public claimed;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
    
     
    event Bury(address indexed target, uint256 value);
    
     
    event Claim(address indexed target, address indexed payout, address indexed fee);

     
    function OysterPearl() public {
        owner = msg.sender;
        totalSupply = 0;
        
         
        totalSupply += 25000000 * 10 ** uint256(decimals);
        
         
        totalSupply += 75000000 * 10 ** uint256(decimals);
        
         
        totalSupply += 1000000 * 10 ** uint256(decimals);
        
         
        balanceOf[owner] = totalSupply;
        
        claimAmount = 5 * 10 ** (uint256(decimals) - 1);
        payAmount = 4 * 10 ** (uint256(decimals) - 1);
        feeAmount = 1 * 10 ** (uint256(decimals) - 1);
        
         
        epoch = 60;
        
         
        retentionMax = 40 * 10 ** uint256(decimals);
    }
    
    modifier onlyOwner {
         
        require(!ownerLock);
        
         
        require(block.number < 8000000);
        
         
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyOwnerForce {
         
        require(msg.sender == owner);
        _;
    }
    
     
    function transferOwnership(address newOwner) public onlyOwnerForce {
        owner = newOwner;
    }
    
     
    function withdrawFunds() public onlyOwnerForce {
        owner.transfer(this.balance);
    }
    
     
    function selfLock() public onlyOwner {
         
        require(saleClosed);
         
        ownerLock = true;
    }
    
     
    function amendClaim(uint8 claimAmountSet, uint8 payAmountSet, uint8 feeAmountSet) public onlyOwner {
        require(claimAmountSet == (payAmountSet + feeAmountSet));
        
        claimAmount = claimAmountSet * 10 ** (uint256(decimals) - 1);
        payAmount = payAmountSet * 10 ** (uint256(decimals) - 1);
        feeAmount = feeAmountSet * 10 ** (uint256(decimals) - 1);
    }
    
     
    function amendEpoch(uint256 epochSet) public onlyOwner {
         
        epoch = epochSet;
    }
    
     
    function amendRetention(uint8 retentionSet) public onlyOwner {
         
        retentionMax = retentionSet * 10 ** uint256(decimals);
    }
    
     
    function closeSale() public onlyOwner {
         
        require(!saleClosed);
         
        saleClosed = true;
    }

     
    function openSale() public onlyOwner {
         
        require(saleClosed);
         
        saleClosed = false;
    }
    
     
    function bury() public {
         
        require(!buried[msg.sender]);
        
         
        require(balanceOf[msg.sender] > claimAmount);
        
         
        require(balanceOf[msg.sender] <= retentionMax);
        
         
        buried[msg.sender] = true;
        
         
        claimed[msg.sender] = 1;
        
         
        Bury(msg.sender, balanceOf[msg.sender]);
    }
    
     
    function claim(address _payout, address _fee) public {
         
        require(buried[msg.sender]);
        
         
        require(_payout != _fee);
        
         
        require(msg.sender != _payout);
        
         
        require(msg.sender != _fee);
        
         
        require(claimed[msg.sender] == 1 || (block.timestamp - claimed[msg.sender]) >= epoch);
        
         
        require(balanceOf[msg.sender] >= claimAmount);
        
         
        claimed[msg.sender] = block.timestamp;
        
         
        uint256 previousBalances = balanceOf[msg.sender] + balanceOf[_payout] + balanceOf[_fee];
        
         
        balanceOf[msg.sender] -= claimAmount;
        
         
        balanceOf[_payout] += payAmount;
        
         
        balanceOf[_fee] += feeAmount;
        
         
        Transfer(msg.sender, _payout, payAmount);
        Transfer(msg.sender, _fee, feeAmount);
        Claim(msg.sender, _payout, _fee);
        
         
        assert(balanceOf[msg.sender] + balanceOf[_payout] + balanceOf[_fee] == previousBalances);
    }
    
     
    function () payable public {
         
        require(!saleClosed);
        
         
        require(msg.value >= 1 finney);
        
         
        uint256 amount = msg.value * 5000;
        
         
        require(totalSupply + amount <= (500000000 * 10 ** uint256(decimals)));
        
         
        totalSupply += amount;
        
         
        balanceOf[msg.sender] += amount;
        
         
        funds += msg.value;
        
         
        Transfer(this, msg.sender, amount);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(!buried[_from]);
        
         
        if (buried[_to]) {
            require(balanceOf[_to] + _value <= retentionMax);
        }
        
         
        require(_to != 0x0);
        
         
        require(balanceOf[_from] >= _value);
        
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
         
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        
         
        balanceOf[_from] -= _value;
        
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
         
        require(!buried[_spender]);
        
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
         
        require(!buried[msg.sender]);
        
         
        require(balanceOf[msg.sender] >= _value);
        
         
        balanceOf[msg.sender] -= _value;
        
         
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
         
        require(!buried[_from]);
        
         
        require(balanceOf[_from] >= _value);
        
         
        require(_value <= allowance[_from][msg.sender]);
        
         
        balanceOf[_from] -= _value;
        
         
        allowance[_from][msg.sender] -= _value;
        
         
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}