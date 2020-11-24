 

 

pragma solidity ^0.5.2;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;




 
 

 


contract brothers is Ownable {  
    using SafeMath for uint256;

    event EthIssued(uint256 value);

    event AddressAdded(address newbrother);
    event AddressRemoved(address oldbrother);


    address payable[] bizbrothers;
    address payable[] devbrothers;
    address payable[] tradebrothers;
    address payable[] socialbrothers;
    uint256 public pool;
    uint256 public serviceshare;

    
    uint256 public total_distributed;

    address payable service_costs = 0x5315845c377DC739Db349c24760955bf3aA88e2a;

    constructor() public Ownable() {
        
        emit EthIssued(0);
        
        bizbrothers.push(0x7A6C7Da79Ac78C9f473D8723E1e62030414B6909);
        bizbrothers.push(0x5736AF088b326DaFCbF8fCBe005241245E853a0F);
        bizbrothers.push(0x1f6bca1657e2B08A31A562B14c6A5c7e49661eb2);
        
        devbrothers.push(0x73D0e9F8dACa563A50fd70498Be9390088594E72);

        tradebrothers.push(0xC02bc79F386685CE4bAEc9243982BAf9163A06E7);
        tradebrothers.push(0x27b8e7fffC5d3DC967c96b2cA0E7EC028268A2b6);
        tradebrothers.push(0x4C1f6069D12d7110985b48f963084C3ccf48aB06);

        socialbrothers.push(0xe91717B09Cd9D0e8f548EC5cE2921da9C2367356);
    }

    function () external payable {
        
    }

    function distributepool() external payable {
         
        
        pool = address(this).balance;
        if(msg.value > 0){
            pool = pool + msg.value;
        }
        serviceshare = pool / 100 * 10;
        service_costs.transfer(serviceshare);
        pool = pool - serviceshare;

        uint256 bizshare = pool / 8 * 3;
        for(uint256 i = 0; i < bizbrothers.length; i++){
            bizbrothers[i].transfer(bizshare / bizbrothers.length);
        }

        uint256 devshare = pool / 8 * 1;
        for(uint256 i = 0; i < devbrothers.length; i++){
            devbrothers[i].transfer(devshare / devbrothers.length);
        }

        uint256 tradeshare = pool / 8 * 3;
        for(uint256 i = 0; i < tradebrothers.length; i++){
            tradebrothers[i].transfer(tradeshare / tradebrothers.length);
        }

        uint256 socialshare = pool / 8 * 1;
        for(uint256 i = 0; i < socialbrothers.length; i++){
            socialbrothers[i].transfer(socialshare / socialbrothers.length);
        }

    }
 
    function addbizbrother(address payable newbrother) external onlyOwner(){
        bizbrothers.push(newbrother);
        emit AddressAdded(newbrother);
    }

    function adddevbrother(address payable newbrother) external onlyOwner(){
        bizbrothers.push(newbrother);
        emit AddressAdded(newbrother);
    }

    function addtradebrother(address payable newbrother) external onlyOwner(){
        bizbrothers.push(newbrother);
        emit AddressAdded(newbrother);
    }

    function addsocialbrother(address payable newbrother) external onlyOwner(){
        bizbrothers.push(newbrother);
        emit AddressAdded(newbrother);
    }

    function removebrother(address payable oldbrother) external onlyOwner(){
        for(uint256 i = 0; i < bizbrothers.length; i++){
            if(bizbrothers[i] == oldbrother){
                for (uint j = i; j < bizbrothers.length-1; j++){
                    bizbrothers[j] = bizbrothers[j+1];
                }
                bizbrothers.length--;
            }

        }
        for(uint256 i = 0; i < devbrothers.length; i++){
            if(devbrothers[i] == oldbrother){
                for (uint j = i; j < devbrothers.length-1; j++){
                    devbrothers[j] = devbrothers[j+1];
                }
                devbrothers.length--;
            }

        }
        for(uint256 i = 0; i < tradebrothers.length; i++){
            if(tradebrothers[i] == oldbrother){
                for (uint j = i; j < tradebrothers.length-1; j++){
                    tradebrothers[j] = tradebrothers[j+1];
                }
                tradebrothers.length--;
            }

        }
        for(uint256 i = 0; i < socialbrothers.length; i++){
            if(socialbrothers[i] == oldbrother){
                for (uint j = i; j < socialbrothers.length-1; j++){
                    socialbrothers[j] = socialbrothers[j+1];
                }
                socialbrothers.length--;
            }

        }

    }


}