 

 
pragma solidity 0.4.23;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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

    mapping(address => uint256) internal balances;

    uint256 internal totalSupply_;

     
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

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

 
contract NLCToken is StandardToken {
     
    using SafeMath for uint256;

     
    string public constant name = "Nutrilife OU";
    string public constant symbol = "NLC";
    uint8 public constant decimals = 18;  
    
     
    address public nlcAdminAddress;
    uint256 public weiRaised;
    uint256 public rate;

    modifier onlyAdmin {
        require(msg.sender == nlcAdminAddress);
        _;
    }
    
     
    event Investment(address indexed investor, uint256 value);
    event TokenPurchaseRequestFromInvestment(address indexed investor, uint256 token);
    event ApproveTokenPurchaseRequest(address indexed investor, uint256 token);
    
     
    uint256 public constant INITIAL_SUPPLY = 500000000 * 10**uint256(decimals);
    mapping(address => uint256) public _investorsVault;
    mapping(address => uint256) public _investorsInvestmentInToken;

     
    constructor(address _nlcAdminAddress, uint256 _rate) public {
        require(_nlcAdminAddress != address(0));
        
        nlcAdminAddress = _nlcAdminAddress;
        totalSupply_ = INITIAL_SUPPLY;
        rate = _rate;

        balances[_nlcAdminAddress] = totalSupply_;
    }


     
    function () external payable {
        investFund(msg.sender);
    }

     
    function investFund(address _investor) public payable {
         
        uint256 weiAmount = msg.value;
        
        _preValidatePurchase(_investor, weiAmount);
        
        weiRaised = weiRaised.add(weiAmount);
        
        _trackVault(_investor, weiAmount);
        
        _forwardFunds();

        emit Investment(_investor, weiAmount);
    }
    
     
    function investmentOf(address _investor) public view returns (uint256) {
        return _investorsVault[_investor];
    }

     
    function purchaseTokenFromInvestment(uint256 _ethInWei) public {
             
            require(_investorsVault[msg.sender] != 0);

             
            uint256 _token = _getTokenAmount(_ethInWei);
            
            _investorsVault[msg.sender] = _investorsVault[msg.sender].sub(_ethInWei);

            _investorsInvestmentInToken[msg.sender] = _investorsInvestmentInToken[msg.sender].add(_token);
            
            emit TokenPurchaseRequestFromInvestment(msg.sender, _token);
    }

     
    function tokenInvestmentRequest(address _investor) public view returns (uint256) {
        return _investorsInvestmentInToken[_investor];
    }

     
    function approveTokenInvestmentRequest(address _investor) public onlyAdmin {
         
        uint256 token = _investorsInvestmentInToken[_investor];
        require(token != 0);
         
        super.transfer(_investor, _investorsInvestmentInToken[_investor]);
        
        _investorsInvestmentInToken[_investor] = _investorsInvestmentInToken[_investor].sub(token);
        
        emit ApproveTokenPurchaseRequest(_investor, token);
    }

    
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        
         
        require(_weiAmount >= 0.5 ether);
    }

    
    function _trackVault(address _investor, uint256 _weiAmount) internal {
        _investorsVault[_investor] = _investorsVault[_investor].add(_weiAmount);
    }

     
    function _forwardFunds() internal {
        nlcAdminAddress.transfer(msg.value);
    }

     
    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        return _weiAmount.mul(rate).div(1 ether);
    }

}