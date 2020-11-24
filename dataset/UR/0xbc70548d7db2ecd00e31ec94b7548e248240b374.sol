 

pragma solidity ^0.4.23;

contract ERC20_AIG{
    
    string public name; 
    string public symbol; 
    uint8 public decimals = 18; 
    uint256 public totalSupply; 
    mapping (address => uint256) public balanceOf; 
    mapping (address => bool) internal adminGroup;
    bool internal isAct = true;
    
    uint256 public price;
    
    address internal beneficiaries; 
    
     
	event Transfer(address indexed from, address indexed to, uint256 value);
	 
	event SendEth(address indexed to, uint256 value);
    
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 priceBuy
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        beneficiaries = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        adminGroup[msg.sender] = true;
        price = priceBuy;
    }
    
    modifier onlyAdmin() {  
        require(adminGroup[msg.sender]);
        _;
    }
    
    modifier isActivity() {  
        require(isAct);
        _;
    }
    
    function () public payable isActivity{
		require(price >= 0);
		uint256 buyNum = msg.value /10000 * price;
		require(buyNum <= balanceOf[beneficiaries]);
		balanceOf[beneficiaries] -= buyNum;
		balanceOf[msg.sender] += buyNum;
		if(beneficiaries.send(msg.value)){
			emit SendEth(beneficiaries, msg.value);
		}
		emit Transfer(beneficiaries, msg.sender, buyNum);
	}
	
	
	function transfer(address _to, uint256 _value) public isActivity{
	    _transfer(msg.sender, _to, _value);
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
	
	
	function addTokenCoin(uint256 addToken) public onlyAdmin{
		require(addToken >= 0);
		addToken = addToken * 10 ** uint256(decimals);
		totalSupply += addToken;
		balanceOf[beneficiaries] += addToken;
		
	}
	
	function setOption(uint256 priceBuy)public onlyAdmin{
		price = priceBuy;
	}
    
    function setAdmin(address _address,bool _purview)public onlyAdmin{
        adminGroup[_address] = _purview;
    }
	
	function setOpen(bool _isAct) public onlyAdmin{
		isAct = _isAct;
	}
	
	function killYourself()public onlyAdmin{
		selfdestruct(beneficiaries);
	}


}