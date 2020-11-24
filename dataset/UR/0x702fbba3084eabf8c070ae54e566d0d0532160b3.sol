 

pragma solidity >=0.4.22 <0.6.0;

contract owned {
    address public owner;

    constructor() public {
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract TokenBase {
     
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor() public {
        totalSupply = 1;                       
        balanceOf[msg.sender] = totalSupply;   
        name = "Microcoin";                    
        symbol = "MCR";                        
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
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

contract Microcoin is owned, TokenBase {
    uint256 public buyPrice;
    bool public canBuy;

    mapping (address => bool) public isPartner;
    mapping (address => uint256) public partnerMaxMint;

     
    constructor() TokenBase() public {
        canBuy = false;
        buyPrice = 672920000000000;
    }

     
     
     
    function registerPartner(address partnerAddress, uint256 maxMint) onlyOwner public {
        isPartner[partnerAddress] = true;
        partnerMaxMint[partnerAddress] = maxMint;
    }

     
     
     
    function editPartnerMaxMint(address partnerAddress, uint256 maxMint) onlyOwner public {
        partnerMaxMint[partnerAddress] = maxMint;
    }

     
     
    function removePartner(address partnerAddress) onlyOwner public {
        isPartner[partnerAddress] = false;
        partnerMaxMint[partnerAddress] = 0;
    }

     
    function _mintToken(address target, uint256 mintedAmount, bool purchased) internal {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
        if (purchased == true) {
             
            balanceOf[owner] += mintedAmount;
            totalSupply += mintedAmount;
            emit Transfer(address(0), address(this), mintedAmount);
            emit Transfer(address(this), owner, mintedAmount);
        }
    }
    
     
     
     
    function mintToken(address target, uint256 mintedAmount) public {
        require(isPartner[msg.sender] == true);
        require(partnerMaxMint[msg.sender] >= mintedAmount);
        _mintToken(target, mintedAmount, true);
    }

     
     
     
     
    function adminMintToken(address target, uint256 mintedAmount, bool simulatePurchase) onlyOwner public {
        _mintToken(target, mintedAmount, simulatePurchase);
    }

     
     
    function setPrices(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }

     
     
    function toggleBuy(bool newCanBuy) onlyOwner public {
        canBuy = newCanBuy;
    }

     
    function () payable external {
        if (canBuy == true) {
            uint amount = msg.value / buyPrice;                
            _mintToken(address(this), amount, true);           
            _transfer(address(this), msg.sender, amount);      
        }
    }

     
    function withdrawEther() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }
}