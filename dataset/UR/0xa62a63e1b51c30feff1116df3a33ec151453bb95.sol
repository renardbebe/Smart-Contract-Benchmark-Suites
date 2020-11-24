 

pragma solidity ^0.4.16;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

interface token {
    function transfer(address receiver, uint amount) public;
}

contract TokenERC20 is token {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;  
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
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
        require(_spender != 0x0);
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
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
}

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




contract Presale is owned {
    address public operations;

    TokenERC20 public myToken;
    uint256 public distributionSupply;
    uint256 public priceOfToken;
    uint256 factor;
    uint public startBlock;
    uint public endBlock;

    uint256 defaultAuthorizedETH;
    mapping (address => uint256) public authorizedETH;

    uint256 public distributionRealized;
    mapping (address => uint256) public realizedETH;
    mapping (address => uint256) public realizedTokenBalance;

     
    function Presale() public {
        operations = 0x249aAb680bAF7ed84e0ebE55cD078650A17162Ca;
        myToken = TokenERC20(0xeaAa3585ffDCc973a22929D09179dC06D517b84d);
        uint256 decimals = uint256(myToken.decimals());
        distributionSupply = 10 ** decimals * 600000;
        priceOfToken = 3980891719745222;
        startBlock = 4909000;
        endBlock   = 4966700;
        defaultAuthorizedETH = 8 ether;
        factor = 10 ** decimals * 3 / 2;
    }

    modifier onlyOperations {
        require(msg.sender == operations);
        _;
    }

    function transferOperationsFunction(address _operations) onlyOwner public {
        operations = _operations;
    }

    function authorizeAmount(address _account, uint32 _valueETH) onlyOperations public {
        authorizedETH[_account] = uint256(_valueETH) * 1 ether;
    }

     
    function () payable public {
        if (msg.sender != owner)
        {
            require(startBlock <= block.number && block.number <= endBlock);

            uint256 senderAuthorizedETH = authorizedETH[msg.sender];
            uint256 effectiveAuthorizedETH = (senderAuthorizedETH > 0)? senderAuthorizedETH: defaultAuthorizedETH;
            require(msg.value + realizedETH[msg.sender] <= effectiveAuthorizedETH);

            uint256 amountETH = msg.value;
            uint256 amountToken = amountETH / priceOfToken * factor;
            distributionRealized += amountToken;
            realizedETH[msg.sender] += amountETH;
            require(distributionRealized <= distributionSupply);

            if (senderAuthorizedETH > 0)
            {
                myToken.transfer(msg.sender, amountToken);
            }
            else
            {
                realizedTokenBalance[msg.sender] += amountToken;
            }
        }
    }

    function transferBalance(address _account) onlyOperations public {
        uint256 amountToken = realizedTokenBalance[_account];
	if (amountToken > 0)
        {
            realizedTokenBalance[_account] = 0;
            myToken.transfer(_account, amountToken);
        }
    }

    function retrieveToken() onlyOwner public {
        myToken.transfer(owner, myToken.balanceOf(this));
    }

    function retrieveETH(uint256 _amount) onlyOwner public {
        owner.transfer(_amount);
    }

    function setBlocks(uint _startBlock, uint _endBlock) onlyOwner public {
        require (_endBlock > _startBlock);
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function setPrice(uint256 _priceOfToken) onlyOwner public {
        require (_priceOfToken > 0);
        priceOfToken = _priceOfToken;
    }
}