 

pragma solidity ^0.4.24;

 
 
 

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
    );
}

contract Ownable {
    address public owner;
    address public master = 0x8fED3492dB590ad34ed42b0F509EB3c9626246Fc;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


   
    constructor() public {
        owner = msg.sender;
    }

   
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

   
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

   
    function transferOwnership(address _newOwner) public {
        require(msg.sender == master);
        _transferOwnership(_newOwner);
    }

   
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Claimable is ERC20Basic, Ownable {

    using SafeMath for uint256;

    struct Claim {
        address claimant;  
        uint256 collateral;  
        uint256 timestamp;   
    }

    struct PreClaim {
        bytes32 msghash;  
        uint256 timestamp;   
    }

     
    uint256 public collateralRate = 5*10**15 wei;

    uint256 public claimPeriod = 60*60*24*180;  
    uint256 public preClaimPeriod = 60*60*24;  

    mapping(address => Claim) public claims;  
    mapping(address => PreClaim) public preClaims;  


    function setClaimParameters(uint256 _collateralRateInWei, uint256 _claimPeriodInDays) public onlyOwner() {
        uint256 claimPeriodInSeconds = _claimPeriodInDays*60*60*24;
        require(_collateralRateInWei > 0);
        require(_claimPeriodInDays > 90);  
        collateralRate = _collateralRateInWei;
        claimPeriod = claimPeriodInSeconds;
        emit ClaimParametersChanged(collateralRate, claimPeriod);
    }

    event ClaimMade(address indexed _lostAddress, address indexed _claimant, uint256 _balance);
    event ClaimPrepared(address indexed _claimer);
    event ClaimCleared(address indexed _lostAddress, uint256 collateral);
    event ClaimDeleted(address indexed _lostAddress, address indexed _claimant, uint256 collateral);
    event ClaimResolved(address indexed _lostAddress, address indexed _claimant, uint256 collateral);
    event ClaimParametersChanged(uint256 _collateralRate, uint256  _claimPeriodInDays);


   

    function prepareClaim(bytes32 _hashedpackage) public{
        preClaims[msg.sender] = PreClaim({
            msghash: _hashedpackage,
            timestamp: block.timestamp
        });
        emit ClaimPrepared(msg.sender);
    }

    function validateClaim(address _lostAddress, bytes32 _nonce) private view returns (bool){
        PreClaim memory preClaim = preClaims[msg.sender];
        require(preClaim.msghash != 0);
        require(preClaim.timestamp + preClaimPeriod <= block.timestamp);
        require(preClaim.timestamp + 2*preClaimPeriod >= block.timestamp);
        return preClaim.msghash == keccak256(abi.encodePacked(_nonce, msg.sender, _lostAddress));
    }

    function declareLost(address _lostAddress, bytes32 _nonce) public payable{
        uint256 balance = balanceOf(_lostAddress);
        require(balance > 0);
        require(msg.value >= balance.mul(collateralRate));
        require(claims[_lostAddress].collateral == 0);
        require(validateClaim(_lostAddress, _nonce));

        claims[_lostAddress] = Claim({
            claimant: msg.sender,
            collateral: msg.value,
            timestamp: block.timestamp
        });
        delete preClaims[msg.sender];
        emit ClaimMade(_lostAddress, msg.sender, balance);
    }

    function getClaimant(address _lostAddress) public view returns (address){
        return claims[_lostAddress].claimant;
    }

    function getCollateral(address _lostAddress) public view returns (uint256){
        return claims[_lostAddress].collateral;
    }

    function getTimeStamp(address _lostAddress) public view returns (uint256){
        return claims[_lostAddress].timestamp;
    }

    function getPreClaimTimeStamp(address _claimerAddress) public view returns (uint256){
        return preClaims[_claimerAddress].timestamp;
    }

    function getMsgHash(address _claimerAddress) public view returns (bytes32){
        return preClaims[_claimerAddress].msghash;
    }

     
    function clearClaim() public returns (uint256){
        uint256 collateral = claims[msg.sender].collateral;
        if (collateral != 0){
            delete claims[msg.sender];
            msg.sender.transfer(collateral);
            emit ClaimCleared(msg.sender, collateral);
            return collateral;
        } else {
            return 0;
        }
    }

    
    function resolveClaim(address _lostAddress) public returns (uint256){
        Claim memory claim = claims[_lostAddress];
        require(claim.collateral != 0, "No claim found");
        require(claim.claimant == msg.sender);
        require(claim.timestamp + claimPeriod <= block.timestamp);
        address claimant = claim.claimant;
        delete claims[_lostAddress];
        claimant.transfer(claim.collateral);
        internalTransfer(_lostAddress, claimant, balanceOf(_lostAddress));
        emit ClaimResolved(_lostAddress, claimant, claim.collateral);
        return claim.collateral;
    }

    function internalTransfer(address _from, address _to, uint256 _value) internal;

      
    function deleteClaim(address _lostAddress) public onlyOwner(){
        Claim memory claim = claims[_lostAddress];
        require(claim.collateral != 0, "No claim found");
        delete claims[_lostAddress];
        claim.claimant.transfer(claim.collateral);
        emit ClaimDeleted(_lostAddress, claim.claimant, claim.collateral);
    }

}

contract AlethenaShares is ERC20, Claimable {

    string public constant name = "Alethena Equity";
    string public constant symbol = "ALEQ";
    uint8 public constant decimals = 0;  

    using SafeMath for uint256;

       
    string public constant termsAndConditions = "shares.alethena.com";

    mapping(address => uint256) balances;
    uint256 totalSupply_;         
    uint256 totalShares_ = 1397188;  

    event Mint(address indexed shareholder, uint256 amount, string message);
    event Unmint(uint256 amount, string message);

   
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

   
    function totalShares() public view returns (uint256) {
        return totalShares_;
    }

    function setTotalShares(uint256 _newTotalShares) public onlyOwner() {
        require(_newTotalShares >= totalSupply());
        totalShares_ = _newTotalShares;
    }

   
    function mint(address shareholder, uint256 _amount, string _message) public onlyOwner() {
        require(_amount > 0);
        require(totalSupply_.add(_amount) <= totalShares_);
        balances[shareholder] = balances[shareholder].add(_amount);
        totalSupply_ = totalSupply_ + _amount;
        emit Mint(shareholder, _amount, _message);
    }

 
    function unmint(uint256 _amount, string _message) public onlyOwner() {
        require(_amount > 0);
        require(_amount <= balanceOf(owner));
        balances[owner] = balances[owner].sub(_amount);
        totalSupply_ = totalSupply_ - _amount;
        emit Unmint(_amount, _message);
    }

   
    bool public isPaused = false;

   
    function pause(bool _pause, string _message, address _newAddress, uint256 _fromBlock) public onlyOwner() {
        isPaused = _pause;
        emit Pause(_pause, _message, _newAddress, _fromBlock);
    }

    event Pause(bool paused, string message, address newAddress, uint256 fromBlock);

 
 
 

   
    function transfer(address _to, uint256 _value) public returns (bool) {
        clearClaim();
        internalTransfer(msg.sender, _to, _value);
        return true;
    }

    function internalTransfer(address _from, address _to, uint256 _value) internal {
        require(!isPaused);
        require(_to != address(0));
        require(_value <= balances[_from]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

   
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    mapping (address => mapping (address => uint256)) internal allowed;

   
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        internalTransfer(_from, _to, _value);
        return true;
    }

   
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!isPaused);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    event Approval(address approver, address spender, uint256 value);
   
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

   
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        require(!isPaused);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

   
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(!isPaused);
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