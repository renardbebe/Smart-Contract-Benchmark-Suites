 

pragma solidity ^0.4.0;


 
contract Ownable {
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

}


 
library SafeMathLibExt {

    function times(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divides(uint a, uint b) returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function minus(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function plus(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c>=a);
        return c;
    }

}


contract Destructable is Ownable {

    function burn() public onlyOwner {
        selfdestruct(owner);
    }

}


contract TokensContract {
    function balanceOf(address who) public constant returns (uint256);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
}

contract Insurance is Destructable, SafeMath  {

    uint startClaimDate;
    uint endClaimDate;
    uint rewardWeiCoefficient;
    uint256 buyPrice;
    address tokensContractAddress;
    uint256 ichnDecimals;

    mapping (address => uint256) buyersBalances;

    struct ClientInsurance {
        uint256 tokensCount;
        bool isApplied;
        bool exists;
        bool isBlocked;
    }


    mapping(address => ClientInsurance) insurancesMap;


    function Insurance() public {
         
        tokensContractAddress = 0x3ab7b695573017eeBD6377c433F9Cf3eF5B4cd48;

         
        startClaimDate = 1609372800;
        endClaimDate = 1612224000;


         
        rewardWeiCoefficient = 100000000000000000;

         
        buyPrice = 50000000000000000;

         
        ichnDecimals = 1000000000000000000;
    }

     
    function () public payable {
        throw;
    }

     
    function addEth() public payable onlyOwner {
    }
    
     
    function transferEthTo(address to, uint256 amount) public payable onlyOwner {
        require(address(this).balance > amount);
        to.transfer(amount);
    }

     
    function buy() public payable {
         
        require(buyersBalances[msg.sender] == 0);

         
        require(msg.value == buyPrice);

         
        require(hasTokens(msg.sender));

         
        buyersBalances[msg.sender] = safeAdd(buyersBalances[msg.sender], msg.value);
    }

    function isClient(address clientAddress) public constant onlyOwner returns(bool) {
        return insurancesMap[clientAddress].exists;
    }

    function addBuyer(address clientAddress, uint256 tokensCount) public onlyOwner {
        require( (clientAddress != address(0)) && (tokensCount > 0) );

         
        require(buyersBalances[clientAddress] == buyPrice);

         
        require(!insurancesMap[clientAddress].exists);

         
        require(getTokensCount(clientAddress) >= tokensCount);

        insurancesMap[clientAddress] = ClientInsurance(tokensCount, false, true, false);
    }

    function claim(address to, uint256 returnedTokensCount) public onlyOwner {
         
        require(now > startClaimDate && now < endClaimDate);

         
        require( (to != address(0)) && (insurancesMap[to].exists) && (!insurancesMap[to].isApplied) && (!insurancesMap[to].isBlocked) );

         
        require(returnedTokensCount >= insurancesMap[to].tokensCount);

         
        uint amount = getRewardWei(to);

        require(address(this).balance > amount);
        insurancesMap[to].isApplied = true;

        to.transfer(amount);
    }

    function blockClient(address clientAddress) public onlyOwner {
        insurancesMap[clientAddress].isBlocked = true;
    }

    function unblockClient(address clientAddress) public onlyOwner {
        insurancesMap[clientAddress].isBlocked = false;
    }

    function isClientBlocked(address clientAddress) public constant onlyOwner returns(bool) {
        return insurancesMap[clientAddress].isBlocked;
    }

     
    function setBuyPrice(uint256 priceWei) public onlyOwner {
        buyPrice = priceWei;
    }

     
    function setTokensContractAddress(address contractAddress) public onlyOwner {
        tokensContractAddress = contractAddress;
    }

     
    function getTokensContractAddress() public constant onlyOwner returns(address) {
        return tokensContractAddress;
    }

    function getRewardWei(address clientAddress) private constant returns (uint256) {
        uint tokensCount = insurancesMap[clientAddress].tokensCount;
        return safeMul(tokensCount, rewardWeiCoefficient);
    }

    function hasTokens(address clientAddress) private constant returns (bool) {
        return getTokensCount(clientAddress) > 0;
    }

    function getTokensCount(address clientAddress) private constant returns (uint256) {
        TokensContract tokensContract = TokensContract(tokensContractAddress);

        uint256 tcBalance = tokensContract.balanceOf(clientAddress);

        return safeDiv(tcBalance, ichnDecimals);
    }
    
     
    function transferTokensTo(address to, uint256 tokensAmount) public onlyOwner {
       TokensContract tokensContract = TokensContract(tokensContractAddress);
       tokensContract.approve(address(this), tokensAmount);
       tokensContract.transferFrom(address(this), to, tokensAmount);
    }
    
    function getStartClaimDate() public constant onlyOwner returns(uint) {
        return startClaimDate;
    }
    
    function getEndClaimDate() public constant onlyOwner returns(uint) {
        return endClaimDate;
    }
}