 

 

pragma solidity ^0.4.24;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event DelegatedTransfer(address indexed from, address indexed to, address indexed delegate, uint256 value, uint256 fee);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owned() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract FourArt is StandardToken, Owned {
    string public constant name = "4ArtCoin";
    string public constant symbol = "4Art";
    uint8 public constant decimals = 18;
    uint256 public sellPrice = 0;  
    uint256 public buyPrice = 0;  
    mapping (address => bool) private SubFounders;       
    mapping (address => bool) private TeamAdviserPartner;
    
     
    address private FounderAddress1;
    address private FounderAddress2;
    address private FounderAddress3;
    address private FounderAddress4;
    address private FounderAddress5;
    address private teamAddress;
    address private adviserAddress;
    address private partnershipAddress;
    address private bountyAddress;
    address private affiliateAddress;
    address private miscAddress;
    
    function FourArt(
        address _founderAddress1, 
        address _founderAddress2,
        address _founderAddress3, 
        address _founderAddress4, 
        address _founderAddress5, 
        address _teamAddress, 
        address _adviserAddress, 
        address _partnershipAddress, 
        address _bountyAddress, 
        address _affiliateAddress,
        address _miscAddress
        )  {
        totalSupply = 6500000000e18;
         
        balances[msg.sender] = 4354000000e18;
        FounderAddress1 = _founderAddress1;
        FounderAddress2 = _founderAddress2;
        FounderAddress3 = _founderAddress3;
        FounderAddress4 = _founderAddress4;
        FounderAddress5 = _founderAddress5;
        teamAddress = _teamAddress;
        adviserAddress =  _adviserAddress;
        partnershipAddress = _partnershipAddress;
        bountyAddress = _bountyAddress;
        affiliateAddress = _affiliateAddress;
        miscAddress =  _miscAddress;
        
         
        balances[FounderAddress1] = 1390000000e18;
        balances[FounderAddress2] = 27500000e18;
        balances[FounderAddress3] = 27500000e18;
        balances[FounderAddress4] = 27500000e18;
        balances[FounderAddress5] = 27500000e18;
        balances[teamAddress] = 39000000e18;
        balances[adviserAddress] = 39000000e18;
        balances[partnershipAddress] = 39000000e18;
        balances[bountyAddress] = 65000000e18;
        balances[affiliateAddress] = 364000000e18;
        balances[miscAddress] = 100000000e18;

         
        SubFounders[FounderAddress2] = true;        
        SubFounders[FounderAddress3] = true;        
        SubFounders[FounderAddress4] = true;        
        SubFounders[FounderAddress5] = true;        
        TeamAdviserPartner[teamAddress] = true;     
        TeamAdviserPartner[adviserAddress] = true;  
        TeamAdviserPartner[partnershipAddress] = true;
    }
    
     
    function () public payable {
    }

     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        require(now > 1543536000);  
        uint amount = msg.value.div(buyPrice);        
        _transfer(owner, msg.sender, amount);    
    }

     
    function sell(uint256 amount) public {
        require(now > 1543536000);  
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        uint256 requiredBalance = amount.mul(sellPrice);
        require(this.balance >= requiredBalance);   
        balances[msg.sender] -= amount;
        balances[owner] += amount;
        Transfer(msg.sender, owner, amount); 
        msg.sender.transfer(requiredBalance);     
    }

    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        Transfer(_from, _to, _value);
    }

     
    function transferBalanceToOwner(uint256 _value) public onlyOwner {
        require(_value <= this.balance);
        owner.transfer(_value);
    }
    
     
    function transferTokens(address _to, uint256 _tokens) lockTokenTransferBeforeStage4 TeamTransferConditions(_tokens, msg.sender)   public {
        _transfer(msg.sender, _to, _tokens);
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) lockTokenTransferBeforeStage4 TeamTransferConditions(_value, _from)  public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    modifier lockTokenTransferBeforeStage4{
        if(msg.sender != owner){
           require(now > 1533513600);  
        }
        _;
    }
    
    modifier TeamTransferConditions(uint256 _tokens,  address _address) {
        if(SubFounders[_address]){
            require(now > 1543536000);
            if(now > 1543536000 && now < 1569628800){
                 
                isLocked(_tokens, 24750000e18, _address);
            } 
            if(now > 1569628800 && now < 1601251200){
                
               isLocked(_tokens, 13750000e18, _address);
            }
        }
        
        if(TeamAdviserPartner[_address]){
            require(now > 1543536000);
            if(now > 1543536000 && now < 1569628800){
                 
                isLocked(_tokens, 33150000e18, _address);
            } 
            if(now > 1569628800 && now < 1601251200){
                
               isLocked(_tokens, 23400000e18, _address);
            }
        }
        _;
    }

     
    function isLocked(uint256 _value,uint256 remainingTokens, address _address)  internal returns (bool) {
            uint256 remainingBalance = balances[_address].sub(_value);
            require(remainingBalance >= remainingTokens);
            return true;
    }
}