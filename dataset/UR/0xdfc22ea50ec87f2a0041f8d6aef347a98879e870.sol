 

pragma solidity ^0.4.19;

 
contract ERC20Basic {
    function totalSupply() public view returns(uint256);
    
    function balanceOf(address who) public view returns(uint256);
    
    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    uint256 totalSupply_;
    
     
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }
    
     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }
    
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns(uint256);
    
    function transferFrom(address from, address to, uint256 value) public returns(bool);
    
    function approve(address spender, uint256 value) public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {
    
    mapping(address => mapping(address => uint256)) internal allowed;
    
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }
    
     
    function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
}
 
contract Pausable is Ownable {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
     
    modifier whenPaused() {
        require(paused);
        _;
    }
    
     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }
    
     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
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
    
     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
    
     
    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

 
contract PausableToken is StandardToken, Pausable {
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns(bool) {
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns(bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public whenNotPaused returns(bool) {
        return super.approve(_spender, _value);
    }
    
    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns(bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns(bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
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

 
contract MavinToken is MintableToken, PausableToken {
    
    string public constant name = "Mavin Token";
    string public constant symbol = "MVN";
    uint8 public constant decimals = 18;
    address public creator;
    
    function MavinToken()
    public
    Ownable()
    MintableToken()
    PausableToken() {
        creator = msg.sender;
        paused = true;
    }
    
    function finalize()
    public
    onlyOwner {
        finishMinting();  
        unpause();
    }
    
    
    function ownershipToCreator()
    public {
        require(creator == msg.sender);
        owner = msg.sender;
    }
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


library Referral {
    
     
    event LogRef(address member, address referrer);
    
    struct Node {
        address referrer;
        bool valid;
    }
    
     
    struct Tree {
        mapping(address => Referral.Node) nodes;
    }
    
    function addMember(
                       Tree storage self,
                       address _member,
                       address _referrer
                       
                       )
    internal
    returns(bool success) {
        Node memory memberNode;
        memberNode.referrer = _referrer;
        memberNode.valid = true;
        self.nodes[_member] = memberNode;
        LogRef(_member, _referrer);
        return true;
    }
}


contract AffiliateTreeStore is Ownable {
    using SafeMath for uint256;
    using Referral for Referral.Tree;
    
    address public creator;
    
    Referral.Tree affiliateTree;
    
    function AffiliateTreeStore()
    public {
        creator = msg.sender;
    }
    
    function ownershipToCreator()
    public {
        require(creator == msg.sender);
        owner = msg.sender;
    }
    
    function getNode(
                     address _node
                     )
    public
    view
    returns(address referrer) {
        Referral.Node memory n = affiliateTree.nodes[_node];
        if (n.valid == true) {
            return _node;
        }
        return 0;
    }
    
    function getReferrer(
                         address _node
                         )
    public
    view
    returns(address referrer) {
        Referral.Node memory n = affiliateTree.nodes[_node];
        if (n.valid == true) {
            return n.referrer;
        }
        return 0;
    }
    
    function addMember(
                       address _member,
                       address _referrer
                       )
    
    public
    onlyOwner
    returns(bool success) {
        return affiliateTree.addMember(_member, _referrer);
    }
    
    
     
    function() public {
        revert();
    }
    
}
 
contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;
    
    event Released(uint256 amount);
    event Revoked();
    
     
    address public beneficiary;
    
    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    
    bool public revocable;
    
    mapping(address => uint256) public released;
    mapping(address => bool) public revoked;
    
     
    function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
        require(_beneficiary != address(0));
        require(_cliff <= _duration);
        
        beneficiary = _beneficiary;
        revocable = _revocable;
        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;
    }
    
     
    function release(ERC20Basic token) public {
        uint256 unreleased = releasableAmount(token);
        
        require(unreleased > 0);
        
        released[token] = released[token].add(unreleased);
        
        token.safeTransfer(beneficiary, unreleased);
        
        Released(unreleased);
    }
    
     
    function revoke(ERC20Basic token) public onlyOwner {
        require(revocable);
        require(!revoked[token]);
        
        uint256 balance = token.balanceOf(this);
        
        uint256 unreleased = releasableAmount(token);
        uint256 refund = balance.sub(unreleased);
        
        revoked[token] = true;
        
        token.safeTransfer(owner, refund);
        
        Revoked();
    }
    
     
    function releasableAmount(ERC20Basic token) public view returns(uint256) {
        return vestedAmount(token).sub(released[token]);
    }
    
     
    function vestedAmount(ERC20Basic token) public view returns(uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);
        
        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration) || revoked[token]) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(start)).div(duration);
        }
    }
}


contract AffiliateManager is Pausable {
    using SafeMath for uint256;
    
    AffiliateTreeStore public affiliateTree;  
    
     
    MavinToken public token;
     
    uint256 public endTime;
     
    uint256 public cap;
     
    address public vault;
     
    uint256 public mvnpereth;
     
    uint256 public weiRaised;
     
    uint256 public minAmountWei;
     
    address creator;
    
    
    function AffiliateManager(
                              address _token,
                              address _treestore
                              )
    public {
        creator = msg.sender;
        token = MavinToken(_token);
        endTime = 1536969600;  
        vault = 0xD0b40D3bfd8DFa6ecC0b357555039C3ee1C11202;
        mvnpereth = 100;
        
        minAmountWei = 0.01 ether;
        cap = 32000 ether;
        
        affiliateTree = AffiliateTreeStore(_treestore);
    }
    
     
    event LogBuyTokens(address owner, uint256 tokens, uint256 tokenprice);
     
    event LogId(address owner, uint48 id);
    
    modifier onlyNonZeroAddress(address _a) {
        require(_a != address(0));
        _;
    }
    
    modifier onlyDiffAdr(address _referrer, address _sender) {
        require(_referrer != _sender);
        _;
    }
    
    function initAffiliate() public onlyOwner returns(bool) {
         
        bool success1 = affiliateTree.addMember(vault, 0);  
        bool success2 = affiliateTree.addMember(msg.sender, vault);  
        return success1 && success2;
    }
    
    
     
    function finalizeCrowdsale() public onlyOwner returns(bool) {
        
        pause();
        
        uint256 totalSupply = token.totalSupply();
        
         
        TokenVesting team = new TokenVesting(vault, now, 24 weeks, 1 years, false);
        uint256 teamTokens = totalSupply.div(60).mul(16);
        token.mint(team, teamTokens);
        
        uint256 reserveTokens = totalSupply.div(60).mul(18);
        token.mint(vault, reserveTokens);
        
        uint256 advisoryTokens = totalSupply.div(60).mul(6);
        token.mint(vault, advisoryTokens);
        
        token.transferOwnership(creator);
    }
    
    function validPurchase() internal constant returns(bool) {
        bool withinCap = weiRaised.add(msg.value) <= cap;
        bool withinTime = endTime > now;
        bool withinMinAmount = msg.value >= minAmountWei;
        return withinCap && withinTime && withinMinAmount;
    }
    
    function presaleMint(
                         address _beneficiary,
                         uint256 _amountmvn,
                         uint256 _mvnpereth
                         
                         )
    public
    onlyOwner
    returns(bool) {
        uint256 _weiAmount = _amountmvn.div(_mvnpereth);
        require(_beneficiary != address(0));
        token.mint(_beneficiary, _amountmvn);
         
        weiRaised = weiRaised.add(_weiAmount);
        
        LogBuyTokens(_beneficiary, _amountmvn, _mvnpereth);
        return true;
    }
    
    function joinManual(
                        address _referrer,
                        uint48 _id
                        )
    public
    payable
    whenNotPaused
    onlyDiffAdr(_referrer, msg.sender)  
    onlyDiffAdr(_referrer, this)  
    returns(bool) {
        LogId(msg.sender, _id);
        return join(_referrer);
    }
    
    
    function join(
                  address _referrer
                  )
    public
    payable
    whenNotPaused
    onlyDiffAdr(_referrer, msg.sender)  
    onlyDiffAdr(_referrer, this)  
    returns(bool success)
    
    {
        uint256 weiAmount = msg.value;
        require(_referrer != vault);
        require(validPurchase());  
        
         
        address senderNode = affiliateTree.getNode(msg.sender);
        
         
        if (senderNode != address(0)) {
            _referrer =  affiliateTree.getReferrer(msg.sender);
        }
        
         
        address referrerNode = affiliateTree.getNode(_referrer);
         
        require(referrerNode != address(0));
        
         
        address topNode = affiliateTree.getReferrer(_referrer);
         
        require(topNode != address(0));
        require(topNode != msg.sender);  
        
        
         
        if (senderNode == address(0)) {
            affiliateTree.addMember(msg.sender, _referrer);
        }
        
        success = buyTokens(msg.sender, weiAmount);
        
        uint256 parentAmount = 0;
        uint256 rootAmount = 0;
        
         
        parentAmount = weiAmount.div(100).mul(5);  
        referrerNode.transfer(parentAmount);
        buyTokens(referrerNode, parentAmount);
        
         
        rootAmount = weiAmount.div(100).mul(3);  
        buyTokens(topNode, rootAmount);
        topNode.transfer(rootAmount);
        
        vault.transfer(weiAmount.sub(parentAmount).sub(rootAmount));  
        
        return success;
    }
    
    function buyTokens(
                       address _beneficiary,
                       uint256 _weiAmount
                       )
    internal
    returns(bool success) {
        require(_beneficiary != address(0));
        uint256 tokens = 0;
        
        tokens = _weiAmount.mul(mvnpereth);
        
         
        weiRaised = weiRaised.add(_weiAmount);
        success = token.mint(_beneficiary, tokens);
        
        LogBuyTokens(_beneficiary, tokens, mvnpereth);
        return success;
    }
    
    function updateMVNRate(uint256 _value) onlyOwner public returns(bool success) {
        mvnpereth = _value;
        return true;
    }
    
    function updateMinAmountWei(uint256 _value) onlyOwner public returns(bool success) {
        minAmountWei = _value;
        return true;
    }
    
    function balanceOf(address _owner) public constant returns(uint256 balance) {
        return token.balanceOf(_owner);
    }
    
     
    function() public {
        revert();
    }
    
}