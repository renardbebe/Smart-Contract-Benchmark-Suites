 

pragma solidity ^0.4.6;
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

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract SwapToken is owned {
     
    
    string public standard = 'Token 0.1';

     
    string public buyerTokenName;
    string public buyerSymbol;
    uint8 public buyerDecimals;
    uint256 public totalBuyerSupply;
    
     
    string public issuerTokenName;
    string public issuerSymbol;
    uint8 public issuerDecimals;
    uint256 public totalIssuerSupply;
    
     
    uint256 public buyPrice;
    uint256 public issuePrice;
    address public project_wallet;
    address public collectionFunds;
    uint public startBlock;
    uint public endBlock;
    
     
    function SwapToken(
        string _buyerTokenName,
        string _buyerSymbol,
        uint8 _buyerDecimals,
        string _issuerTokenName,
        string _issuerSymbol,
        uint8 _issuerDecimals,
        address _collectionFunds,
        uint _startBlock,
        uint _endBlock
        ) {
        buyerTokenName = _buyerTokenName;
        buyerSymbol = _buyerSymbol;
        buyerDecimals = _buyerDecimals;
        issuerTokenName = _issuerTokenName;
        issuerSymbol = _issuerSymbol;
        issuerDecimals = _issuerDecimals;
        collectionFunds = _collectionFunds;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

     
    mapping (address => uint256) public balanceOfBuyer;
    mapping (address => uint256) public balanceOfIssuer;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    
     
    function has_contract_started() private constant returns (bool) {
	    return block.number >= startBlock;
    }
    
     
    function has_contract_ended() private constant returns (bool) {
        return block.number > endBlock;
    }
    
     
    function defineProjectWallet(address target) onlyOwner {
        project_wallet = target;
    }
    
     
    
     
    function mintBuyerToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOfBuyer[target] += mintedAmount;
        totalBuyerSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    
     
    function mintIssuerToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOfIssuer[target] += mintedAmount;
        totalIssuerSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    
     
    
     
    function distroyBuyerToken(uint256 burnAmount) onlyOwner {
        balanceOfBuyer[this] -= burnAmount;
        totalBuyerSupply -= burnAmount;
    }
    
     
    function distroyIssuerToken(uint256 burnAmount) onlyOwner {
        balanceOfIssuer[this] -= burnAmount;
        totalIssuerSupply -= burnAmount;
    }

     
    
     
    function transferBuyer(address _to, uint256 _value) {
        if (balanceOfBuyer[msg.sender] < _value) throw;            
        if (balanceOfBuyer[_to] + _value < balanceOfBuyer[_to]) throw;  
        balanceOfBuyer[msg.sender] -= _value;                      
        balanceOfBuyer[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }
    
     
    function transferIssue(address _to, uint256 _value) {
        if (balanceOfIssuer[msg.sender] < _value) throw;
        if (balanceOfIssuer[_to] + _value < balanceOfIssuer[_to]) throw;
        balanceOfIssuer[msg.sender] -= _value;
        balanceOfIssuer[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        tokenRecipient spender = tokenRecipient(_spender);
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

     
    
     
    function setPrices(uint256 newBuyPrice, uint256 newIssuePrice) onlyOwner {
        buyPrice = newBuyPrice;
        issuePrice = newIssuePrice;
    }

     
    
     
    function buyBuyerTokens() payable {
        if(!has_contract_started()) throw;                   
        if(has_contract_ended()) throw;                      
        uint amount = msg.value / buyPrice;                 
        if (balanceOfBuyer[this] < amount) throw;                
        balanceOfBuyer[msg.sender] += amount;                    
        balanceOfBuyer[this] -= amount;                          
        Transfer(this, msg.sender, amount);                 
    }
    
     
    function buyIssuerTokens() payable {
        uint amount = msg.value / issuePrice;
        if (balanceOfIssuer[this] < amount) throw;
        balanceOfIssuer[msg.sender] += amount;
        balanceOfIssuer[this] -= amount;
        Transfer(this, msg.sender, amount);
    }
    
     
    function moveFunds() onlyOwner {
         
        if (!project_wallet.send(this.balance)) throw;
    }

     
    function () {
        throw;      
    }
}