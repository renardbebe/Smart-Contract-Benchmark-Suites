 

pragma solidity ^0.4.8;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract CardToken is owned {
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    string public ipfs_hash;
    string public description;
    bool public isLocked;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function CardToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        string tokenDescription,
        string ipfsHash
        ) {
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;    
        description = tokenDescription;  
        ipfs_hash = ipfsHash;
        decimals = 0;                             
    }
     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        if (isLocked) { throw; }

        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function lock() onlyOwner  {
        isLocked = true;

    }

    function setDescription(string desc) onlyOwner {
         description = desc;
    }

     
    function () {
        throw;      
    }
}

contract CardFactory {
    address[] public Cards;
    uint256 public CardCount;
   function CardFactory() {
       CardCount = 0;
   }
   function CreateCard(uint256 _initialAmount, string _name, string _symbol, string _desc,string _ipfshash) returns (address) {

        CardToken newToken = (new CardToken(_initialAmount, _name,_symbol, _desc,_ipfshash));
        Cards.push(address(newToken));
        CardCount++;
        newToken.transferOwnership(msg.sender);
        newToken.transfer(msg.sender, _initialAmount);  
        return address(newToken);
    }

      function () {
        throw;      
    }
}