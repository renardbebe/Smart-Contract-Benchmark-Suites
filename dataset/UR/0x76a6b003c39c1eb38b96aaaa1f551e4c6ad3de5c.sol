 

pragma solidity ^0.5.8;

contract ERC20_Coin{
    
    string public name; 
    string public symbol; 
    uint8 public decimals = 18; 
    uint256 public totalSupply; 
    address internal admin; 
    mapping (address => uint256) public balanceOf; 
    bool public isAct = true; 
    bool public openRaise = false; 
    uint256 public raisePrice = 0; 
    address payable internal finance; 
    
     
	event Transfer(address indexed from, address indexed to, uint256 value);
	 
	event SendEth(address indexed to, uint256 value);
    
    constructor(
        uint256 initialSupply, 
        string memory tokenName, 
        string memory tokenSymbol 
     ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        finance = msg.sender;
        admin = msg.sender;
    }

     
    modifier onlyAdmin() { 
        require(msg.sender == admin);
        _;
    }

     
    modifier isActivity() { 
        require(isAct);
        _;
    }

     
    modifier isOpenRaise() { 
        require(openRaise);
        _;
    }

     
    function () external payable isActivity isOpenRaise{
		require(raisePrice >= 0);
		uint256 buyNum = msg.value /10000 * raisePrice;
		require(buyNum <= balanceOf[finance]);
		balanceOf[finance] -= buyNum;
		balanceOf[msg.sender] += buyNum;
        finance.transfer(msg.value);
        emit SendEth(finance, msg.value);
        emit Transfer(finance, msg.sender, buyNum);
	}
    
     
     
    function transfer(address _to, uint256 _value) public isActivity{
	    _transfer(msg.sender, _to, _value);
    }
    
     
    function transferList(address[] memory _tos, uint[] memory _values) public isActivity {
        require(_tos.length == _values.length);
        uint256 _total = 0;
        for(uint256 i;i<_values.length;i++){
            _total += _values[i];
	    }
        require(balanceOf[msg.sender]>=_total);
        for(uint256 i;i<_tos.length;i++){
            _transfer(msg.sender,_tos[i],_values[i]);
	    }
    }
    
     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
	
     
	function setRaisePrice(uint256 _price)public onlyAdmin{
		raisePrice = _price;
	}
	
     
	function setOpenRaise(bool _open) public onlyAdmin{
	    openRaise = _open;
	}
	
     
	function setActivity(bool _isAct) public onlyAdmin{
		isAct = _isAct;
	}
	
     
	function setAdmin(address _address) public onlyAdmin{
       admin = _address;
    }
    
     
    function setMagage(address payable _address) public onlyAdmin{
       finance = _address;
    }
	
     
	function killYourself()public onlyAdmin{
		selfdestruct(finance);
	}
	
}