 

pragma solidity ^0.4.21;

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

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

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

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}


contract APOToken is MintableToken {
    string public name = "Advanced Parimutuel Options";
    string public symbol = "APO";
    uint8 public decimals = 18;
}

contract TokenTimelock {
    
    using SafeERC20 for ERC20Basic;

     
    ERC20Basic public token;

     
    address public beneficiary;

     
    uint256 public releaseTime;
    
    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
    
}

contract RefundVault is Ownable {
    using SafeMath for uint256;   
    
    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;
     
     
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    
     
     
    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }
    
     
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }
    
    function close() onlyOwner public  {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance);  
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

     
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
     
}

contract Crowdsale {
    
  using SafeMath for uint256;
  
     
    ERC20 public token;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;
    
    
    
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public 
    {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
    }
  
     
     
     

    
    function () external payable {
        buyTokens(msg.sender);
    }
    
    
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        
        _forwardFunds();
    }

     
     
     


     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }


     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }


    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }


    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 etherAmount = _weiAmount.mul(rate).div(1 ether);
        return etherAmount;
    }


     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
    
}

contract APOTokenCrowdsale is Ownable, Crowdsale  {

     
    APOToken public token = new APOToken();
    
     
    TokenTimelock public teamTokens;
    TokenTimelock public reserveTokens;
    
     
    address public wallet;
    
     
    address public bountyWallet;
    
    address public privateWallet;
    
     
    RefundVault public vault = new RefundVault(msg.sender);

     
    uint256 public rate = 15000;

     
    uint256 public startTime = 1524650400;
    
     
    uint256 public endTime = 1527069599;
    
     
    uint256 public minAmount = 0.1 * 1 ether;
    
     
    uint256 public softCap = 5500 * 1 ether;
    
     
    uint256 public hardCap = 12700 * 1 ether;
    
     
    uint256 public unlockTime = endTime + 1 years;
    
     
    uint256 public discountPeriod =  1 weeks;
         
     
    bool public isFinalized = false;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Finalized();

    modifier onlyWhileOpen {
        require(now >= startTime && now <= endTime);
        _;
    }
    
     
    function APOTokenCrowdsale() public
    Crowdsale(rate, vault, token) 
    {
        wallet = msg.sender;
        bountyWallet = 0x06F05ebdf3b871813f80C4A1744e66357B0d9e44;
        privateWallet = 0xb62109986F19f710415e71F27fAaF4ece89eFf83;
        teamTokens = new TokenTimelock(token, msg.sender, unlockTime);
        reserveTokens = new TokenTimelock(token, 0x2700C56A67F12899a4CB9316ab6541d90EcE52E9, unlockTime);
    }


    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(_weiAmount >= minAmount);
        require(weiRaised.add(_weiAmount) <= hardCap);
    }
    

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
         
        if (now <= startTime + 1 * discountPeriod) {
            _tokenAmount = _tokenAmount.mul(125).div(100);
        } else if ((now > startTime + 1 * discountPeriod) && (now <= startTime + 2 * discountPeriod))  {
            _tokenAmount = _tokenAmount.mul(115).div(100);
        } else if ((now > startTime + 2 * discountPeriod) && (now <= startTime + 3 * discountPeriod))  {
            _tokenAmount = _tokenAmount.mul(105).div(100);
        }
        
         
        token.mint(_beneficiary, _tokenAmount);
    }


     
    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }


     
    function capReached() public view returns (bool) {
        return weiRaised >= hardCap;
    }


     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasClosed());
        
         
        finalization();
        emit Finalized();

        isFinalized = true;
    }


     
    function finalization() internal {
         
        if (goalReached()) {
            
            vault.close();
            
             
            uint issuedTokenSupply = token.totalSupply();
            uint teamPercent = issuedTokenSupply.mul(20).div(40);
            uint reservePercent = issuedTokenSupply.mul(25).div(40);
            uint bountyPercent = issuedTokenSupply.mul(5).div(40);
            uint privatePercent = issuedTokenSupply.mul(10).div(40);   
            
             
            token.mint(teamTokens, teamPercent);
            token.mint(reserveTokens, reservePercent);
            token.mint(bountyWallet, bountyPercent);
            token.mint(privateWallet, privatePercent);
            
             
            token.finishMinting();
            
        } else {
            vault.enableRefunds();
             
            token.finishMinting();
        }
        
    }


     
    function hasClosed() public view returns (bool) {
        return now > endTime;
    }


     
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }
    

     
    function goalReached() public view returns (bool) {
        return weiRaised >= softCap;
    }

}