 

pragma solidity ^0.4.25;
 
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


     
    constructor() public {
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
    uint256 public totalSupply;
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

 
contract BasicToken is ERC20Basic, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
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


 
contract PromTokenVault is Ownable{
    
    using SafeMath for uint256;

     
     
    uint256 MONTH = 2592000;
     
    address token_;

    bytes4 publicKey = "0x1";
    bytes4 liquidityKey = "0x2";
    bytes4 teamKey = "0x3";
    bytes4 companyKey = "0x4";
    bytes4 privateKey = "0x5";
    bytes4 communityKey = "0x6";
    bytes4 ecosystemKey = "0x7";
    
     
    address liquidity_;
    address team_;
    address company_;
    address private_; 
    address community_;
    address ecosystem_;

     
    mapping (bytes4=>uint256) alreadyWithdrawn;

     
    uint256 TGE_timestamp;
    ERC20 token;
    constructor(
                address _token, 
                address _private, 
                address _ecosystem,
                address _liquidity, 
                address _team, 
                address _company, 
                address _community
                ) public {
        token = ERC20(_token);
        private_ = _private;
        ecosystem_ = _ecosystem;
        liquidity_ = _liquidity;
        team_ = _team;
        company_ = _company; 
        community_ = _community;
        TGE_timestamp = block.timestamp;
    }
    
     
    function getLiqudityAddress() public view returns(address){
        return liquidity_;
    }
    
    function getTeamAddress() public view returns(address){
        return team_;
    }

    function getCompanyAddress() public view returns(address){
        return company_;
    }
    
    function getPrivateAddress() public view returns(address){
        return private_;
    }
    
    function getCommunityAddress() public view returns(address){
        return community_;
    }

    function getEcosystemAddress() public view returns(address){
        return ecosystem_;
    }

     
    function setLiqudityAddress(address _liquidity) public onlyOwner{
        liquidity_ = _liquidity;
    }

    function setTeamAddress(address _team) public onlyOwner{
        team_ = _team;
    }

    function setCompanyAddress(address _company) public onlyOwner{
        company_ = _company;
    }

    function setPrivateAddress(address _private) public onlyOwner{
        private_ = _private;
    }

    function setCommunityAddress(address _community) public onlyOwner{
        community_ = _community;
    }
    function setEcosystemAddress(address _ecosystem) public onlyOwner{
        ecosystem_ = _ecosystem;
    }


        
    function getLiquidityAvailable() public view returns(uint256){
        return getLiquidityReleasable().sub(alreadyWithdrawn[liquidityKey]);
    }    
    function getTeamAvailable() public view returns(uint256){
        return getTeamReleasable().sub(alreadyWithdrawn[teamKey]);
    }    
    function getCompanyAvailable() public view returns(uint256){
        return getCompanyReleasable().sub(alreadyWithdrawn[companyKey]);
    }    
    function getPrivateAvailable() public view returns(uint256){
        return getPrivateReleasable().sub(alreadyWithdrawn[privateKey]);
    }    
    function getCommunityAvailable() public view returns(uint256){
        return getCommunityReleasable().sub(alreadyWithdrawn[communityKey]);
    }    
    function getEcosystemAvailable() public view returns(uint256){
        return getEcosystemReleasable().sub(alreadyWithdrawn[ecosystemKey]);
    }    

     

    function getPercentReleasable(uint256 _part, uint256 _full) internal pure returns(uint256){
        if(_part >= _full){
            _part = _full;
        }
        return _part;
    }
    
    function getMonthsPassed(uint256 _since) internal view returns(uint256){
        return (block.timestamp.sub(_since)).div(MONTH);
    }

     
    function getLiquidityReleasable() public view returns(uint256){
        if(block.timestamp >= TGE_timestamp){
            return token.totalSupply().div(10000).mul(575) - (85000 + 3) * 10 ** uint256(18);
        }else{
            return 0;
        }
    }
    
     
    function getTeamReleasable() public view returns(uint256){
        uint256 unlockDate = TGE_timestamp.add(MONTH.mul(12));
        if(block.timestamp >= unlockDate){
            uint256 totalReleasable = token.totalSupply().div(100).mul(5);
            uint256 monthPassed = getMonthsPassed(unlockDate)+1;
            return totalReleasable.div(100).mul(getPercentReleasable((monthPassed.mul(3)),100));
        }else{
            return 0;
        }
    }

     
     
    function getCompanyReleasable() public view returns(uint256){
        uint256 unlockDate = TGE_timestamp.add(MONTH.mul(12));
        if(now >= unlockDate){
            uint256 totalReleasable = token.totalSupply().div(100).mul(15);
            uint256 monthPassed = getMonthsPassed(unlockDate)+1;
            return totalReleasable.div(100).mul(getPercentReleasable(monthPassed.mul(3),100));
        }else{
            return 0;
        }
    }

     
    function getPrivateReleasable() public view returns(uint256){
        uint256 totalReleasable = token.totalSupply().div(100).mul(20);
        uint256 firstPart = totalReleasable.div(100).mul(40);
        uint256 currentlyReleasable = firstPart;
        uint256 unlockDate = TGE_timestamp.add(MONTH.mul(6));

        if(now >= unlockDate){
            uint256 monthPassed = getMonthsPassed(unlockDate)+1;
            uint256 secondPart = totalReleasable.div(100).mul(getPercentReleasable(monthPassed.mul(10),60));
            currentlyReleasable = firstPart.add(secondPart);
        }
        return currentlyReleasable;
    }

     
    function getCommunityReleasable() public view returns(uint256){
        uint256 unfreezeTimestamp = TGE_timestamp.add(MONTH.mul(6));
        if(now >= unfreezeTimestamp){
            return token.totalSupply().div(100).mul(45);
        }else{
            return 0;
        }
    }

     
    function getEcosystemReleasable() public view returns(uint256){
        uint256 currentlyReleasable = 0;
        if(block.timestamp >= TGE_timestamp){
            uint256 totalReleasable = token.totalSupply().div(100).mul(5);
            uint256 firstPart = totalReleasable.div(100).mul(25);
            uint256 monthPassed = getMonthsPassed(TGE_timestamp);
            uint256 releases = monthPassed.div(6); 
            uint256 secondPart = totalReleasable.div(100).mul(getPercentReleasable(releases.mul(25),75));
            currentlyReleasable = firstPart.add(secondPart);
        }
        return currentlyReleasable;
    }
    function incrementReleased(bytes4 _key, uint256 _amount) internal{
        alreadyWithdrawn[_key]=alreadyWithdrawn[_key].add(_amount);
    }
      
    function releaseLiqudity() public{
        require(token.balanceOf(address(this))>=getLiquidityAvailable(),'Vault does not have enough tokens');
        uint256 toSend = getLiquidityAvailable();
        incrementReleased(liquidityKey,toSend);
        require(token.transfer(liquidity_, toSend),'Token Transfer returned false');
    }
    function releaseTeam() public{
        require(token.balanceOf(address(this))>=getTeamAvailable(),'Vault does not have enough tokens');
        uint256 toSend = getTeamAvailable();
        incrementReleased(teamKey,toSend);
        require(token.transfer(team_, toSend),'Token Transfer returned false');
    }
    function releaseCompany() public{
        require(token.balanceOf(address(this))>=getCompanyAvailable(),'Vault does not have enough tokens');
        uint256 toSend = getCompanyAvailable();
        incrementReleased(companyKey,toSend);
        require(token.transfer(company_, toSend),'Token Transfer returned false');
    }
    function releasePrivate() public{
        require(token.balanceOf(address(this))>=getPrivateAvailable(),'Vault does not have enough tokens');
        uint256 toSend = getPrivateAvailable();
        incrementReleased(privateKey,toSend);
        require(token.transfer(private_, toSend),'Token Transfer returned false');
    }
    function releaseCommunity() public{
        require(token.balanceOf(address(this))>=getCommunityAvailable(),'Vault does not have enough tokens');
        uint256 toSend = getCommunityAvailable();
        incrementReleased(communityKey,toSend);
        require(token.transfer(community_, toSend),'Token Transfer returned false');
    }
    function releaseEcosystem() public{
        require(token.balanceOf(address(this))>=getEcosystemAvailable(),'Vault does not have enough tokens');
        uint256 toSend = getEcosystemAvailable();
        incrementReleased(ecosystemKey,toSend);
        require(token.transfer(ecosystem_, toSend),'Token Transfer returned false');
    }
    function getAlreadyWithdrawn(bytes4 _key) public view returns(uint256){
        return alreadyWithdrawn[_key];
    }
     
     
     
     
     
     

     
     
     
     
     
     
}