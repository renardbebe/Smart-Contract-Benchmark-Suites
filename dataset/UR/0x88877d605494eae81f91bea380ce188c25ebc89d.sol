 

pragma solidity >=0.4.25 <0.6.0;


 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract owned {
    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

contract Pausable is owned {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause()  public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


contract TokenERC20 is Pausable {
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);


     
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        

    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0));
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] =  allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

}

contract Sale is owned, TokenERC20 {

     
    uint256 public soldTokens;
    
    uint256 public startTime = 0;

     
    modifier CheckSaleStatus() {
        
        require (now >= 1574251200);
        _;
    }

}


contract Clipx is TokenERC20, Sale {
    
    using SafeMath for uint256;
    
    uint256 lwei = 10 ** uint256(18);
    uint256 levelEthMax = 120*lwei;
    uint256 startRate = 299280*lwei;
	uint256 public ethAmount=0;
	uint256 public level ;


 
    constructor()
    TokenERC20(10000000, 'BBIN', 'BBIN') public {
        soldTokens = 0;
    }
    
    
    function changeOwnerWithTokens(address payable newOwner) onlyOwner public {
        uint previousBalances = balanceOf[owner] + balanceOf[newOwner];
        balanceOf[newOwner] += balanceOf[owner];
        balanceOf[owner] = 0;
        assert(balanceOf[owner] + balanceOf[newOwner] == previousBalances);
        owner = newOwner;
    }


    function() external payable whenNotPaused CheckSaleStatus {
        uint256 eth_amount = msg.value;
        
        level =(uint256) (ethAmount/levelEthMax) + 1;
       
        require(level < 34);
        
        uint256 amount = exchange(eth_amount);
        
        require(balanceOf[owner] >= amount );
        _transfer(owner, msg.sender, amount);
        soldTokens = soldTokens.add(amount);
         
        owner.transfer(msg.value);
    }
    
    function exchange(uint256 _eth) private returns(uint256){
		
		level =(uint256) (ethAmount/levelEthMax) + 1;
		uint256 curLevelEth = ethAmount%levelEthMax;
		
		if((curLevelEth+_eth)<=levelEthMax) {
			ethAmount = ethAmount + _eth;
            
			return getLevelRate(level)/levelEthMax*_eth;
			
		} else {
			
			uint256 x = levelEthMax-curLevelEth;
			ethAmount = ethAmount + x;
			
			uint256 y = getLevelRate(level)/levelEthMax*x;
			uint256 z = exchange(_eth-x);
			
			return  y + z;
			
		}

	}
	

    
    function getLevelRate(uint256 cc) private returns(uint256){
        
        uint256 lastLevel = startRate;
		
		for(uint256 k=2;k<=cc; k++) {
			
			lastLevel = lastLevel - lastLevel*5/100;
			
		}

        return lastLevel;
    }
}