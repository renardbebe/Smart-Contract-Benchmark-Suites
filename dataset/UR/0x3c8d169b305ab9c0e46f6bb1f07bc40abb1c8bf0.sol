 

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Shaycoin is owned {
     
    string public name;
    string public symbol;
    uint256 public decimals = 18;  
    uint256 public totalSupply;
    uint256 public donations = 0;

    uint256 public price = 200000000000000;

     
    mapping (address => uint256) public balanceOf;
    mapping (uint256 => address) public depositIndex;
    mapping (address => bool) public depositBool;
    uint256 public indexTracker = 0;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function Shaycoin(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** decimals;   
        balanceOf[this] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        if (_to != address(this) && !depositBool[_to]) {
           depositIndex[indexTracker] = _to;
           depositBool[_to] = true;
           indexTracker += 1;
        }
        Transfer(_from, _to, _value);
    }

     
    function buy() payable public {
        uint256 amount = 10 ** decimals * msg.value / price;                
        if (amount > balanceOf[this]) {
            totalSupply += amount - balanceOf[this];
            balanceOf[this] = amount;
        }
        _transfer(this, msg.sender, amount);                                         
    }

     
     
    function sell(uint256 amount) public {
        require(this.balance >= amount * price / 10 ** decimals);       
        _transfer(msg.sender, this, amount);                                     
        msg.sender.transfer(amount * price / 10 ** decimals);           
    }

    function donate() payable public {
        donations += msg.value;
    }

    function collectDonations() onlyOwner public {
        owner.transfer(donations);
        donations = 0;
    }

     
    function killAndRefund() onlyOwner public {
        for (uint256 i = 0; i < indexTracker; i++) {
            depositIndex[i].transfer(balanceOf[depositIndex[i]] * price / 10 ** decimals);
        }
        selfdestruct(owner);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

 }