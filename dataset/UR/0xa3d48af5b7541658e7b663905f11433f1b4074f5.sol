 

pragma solidity ^0.4.17;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract OysterPearl {
     
    string public name = "Oyster Pearl";
    string public symbol = "TPRL";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public funds = 0;
    address public owner;
    bool public saleClosed = false;
    bool public ownerLock = false;
    uint256 public claimAmount;
    uint256 public payAmount;
    uint256 public feeAmount;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public buried;
    mapping (address => uint256) public claimed;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
    
    event Bury(address indexed target, uint256 value);
    
    event Claim(address indexed payout, address indexed fee);

     
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
    }
    
    modifier onlyOwner {
        require(!ownerLock);
        require(block.number < 8000000);
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function selfLock() public onlyOwner {
        ownerLock = true;
    }
    
    function amendAmount(uint8 claimAmountSet, uint8 payAmountSet, uint8 feeAmountSet) public onlyOwner {
        require(claimAmountSet == (payAmountSet + feeAmountSet));
        claimAmount = claimAmountSet * 10 ** (uint256(decimals) - 1);
        payAmount = payAmountSet * 10 ** (uint256(decimals) - 1);
        feeAmount = feeAmountSet * 10 ** (uint256(decimals) - 1);
    }
    
    function closeSale() public onlyOwner {
        saleClosed = true;
    }

    function openSale() public onlyOwner {
        saleClosed = false;
    }
    
    function bury() public {
        require(balanceOf[msg.sender] > claimAmount);
        require(!buried[msg.sender]);
        buried[msg.sender] = true;
        claimed[msg.sender] = 1;
        Bury(msg.sender, balanceOf[msg.sender]);
    }
    
    function claim(address _payout, address _fee) public {
        require(buried[msg.sender]);
        require(claimed[msg.sender] == 1 || (block.timestamp - claimed[msg.sender]) >= 60);
        require(balanceOf[msg.sender] >= claimAmount);
        claimed[msg.sender] = block.timestamp;
        balanceOf[msg.sender] -= claimAmount;
        balanceOf[_payout] -= payAmount;
        balanceOf[_fee] -= feeAmount;
        Claim(_payout, _fee);
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
    
    function withdrawFunds() public onlyOwner {
        owner.transfer(this.balance);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(!buried[_from]);
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
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
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}