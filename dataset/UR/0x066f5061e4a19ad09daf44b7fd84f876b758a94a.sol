 

pragma solidity ^0.4.24;

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

interface swappingContract {
    function swapAssets(address _target, uint256 _value) external returns(bool success);
}

contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract ZLTt is Ownable {
     
    string public name = "ZLT Test";
    string public symbol = "ZLTt";
    uint8 public decimals = 18;
    uint256 public initialSupply = 120000000000000000000000000;
    uint256 public totalSupply;
    bool public canSwap = false;
    address public swapAddress;
    swappingContract public swapContract;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);


     
    constructor() public {
        
        totalSupply = initialSupply;   
        balanceOf[msg.sender] = totalSupply;                 
    }

     
    function setSwapContract(address _swapAddress) public onlyOwner {
        swapContract = swappingContract(_swapAddress);
        swapAddress = _swapAddress;
        canSwap = true;
    }

    function toggleSwap() public onlyOwner {
        if(canSwap) {
            canSwap = false;
        } else {
            canSwap = true;
        }
    }

     
    function swapThisToken(address _from, uint256 _value) internal returns(bool success) {
        bool isSuccessful;
         
        isSuccessful = swapContract.swapAssets(_from, _value);
        return isSuccessful;
    }


     
    function _transfer(address _from, address _to, uint _value) internal {
        
        bool swapSuccess = true;
        

         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        if(canSwap && _to == swapAddress) {
            swapSuccess = false;
            swapSuccess = swapThisToken(_from, _value);
        }
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances && swapSuccess);
        

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
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}