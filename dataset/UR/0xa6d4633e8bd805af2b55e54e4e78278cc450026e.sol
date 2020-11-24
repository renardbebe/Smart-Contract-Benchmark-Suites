 

 

pragma solidity ^0.5.7;

 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
contract IAllocationToken {
     
    event ExchangeContractUpdated(address exchangeContract);

     
    event InvestmentContractUpdated(address investmentContract);

     
    function updateExchangeContract(address _exchangeContract) external;

     
    function updateInvestmentContract(address _investmentContract) external;

     
    function mint(address _holder, uint256 _tokens) public;

     
    function burn(address _address, uint256 _value) public;
}

 

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value)
        internal
    {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}
 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
 
contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue)
        );
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
 
 
 
contract OpenZeppelinERC20 is StandardToken, Ownable {
    using SafeMath for uint256;

    uint8 public decimals;
    string public name;
    string public symbol;

    constructor(
        uint256 _totalSupply,
        string memory _tokenName,
        uint8 _decimals,
        string memory _tokenSymbol
    ) public {
        totalSupply_ = _totalSupply;
        balances[msg.sender] = _totalSupply;

        name = _tokenName;
         
        symbol = _tokenSymbol;
         
        decimals = _decimals;
    }

}

 
contract BurnableToken is BasicToken {
    event Burn(address indexed burner, uint256 value);

     
    function burn(address _address, uint256 _value) public {
        _burn(_address, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(
            _value <= balances[_who],
            "Does not have enough balance to burn"
        );

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

 
 
 
 
contract MintableToken is BasicToken {
    using SafeMath for uint256;

    event Minted(address receiver, uint256 tokens);

     
    function mint(address _holder, uint256 _tokens) public {
        totalSupply_ = totalSupply_.add(_tokens);

        balances[_holder] = balanceOf(_holder).add(_tokens);

        emit Transfer(address(0), _holder, _tokens);
        emit Minted(_holder, _tokens);
    }

}

 
contract BasicAllocationToken is
    IAllocationToken,
    OpenZeppelinERC20,
    MintableToken,
    BurnableToken
{
    address public exchangeContract;  
    address public investmentContract;  

     
    constructor() public OpenZeppelinERC20(0, "BasicAllocationToken", 18, "BAT") {}

     
    modifier allowedToMint() {
        require(
            msg.sender == owner() || msg.sender == exchangeContract,
            "Sender is not allowed to mint tokens."
        );
        _;
    }

     
    modifier allowedToBurn() {
        require(
            msg.sender == investmentContract,
            "Sender is not allowed to burn tokens."
        );
        _;
    }

     
    function updateExchangeContract(address _exchangeContract)
        external
        onlyOwner
    {
        require(
            _exchangeContract != address(0x0),
            "Exchange contract address is not valid."
        );
        exchangeContract = _exchangeContract;

        emit ExchangeContractUpdated(exchangeContract);
    }

     
    function updateInvestmentContract(address _investmentContract)
        external
        onlyOwner
    {
        require(
            _investmentContract != address(0x0),
            "Investment contract address is not valid."
        );
        investmentContract = _investmentContract;

        emit InvestmentContractUpdated(investmentContract);
    }

    function transfer(address _to, uint256 _tokens) public returns (bool) {
        revert("This operation is not allowed");  
    }

    function transferFrom(address _holder, address _to, uint256 _tokens)
        public
        returns (bool)
    {
        revert("This operation is not allowed");  
    }

     
    function mint(address _holder, uint256 _tokens) public allowedToMint {
        super.mint(_holder, _tokens);  
    }

     
    function burn(address _address, uint256 _value) public allowedToBurn {
        super.burn(_address, _value);  
    }

}