 

pragma solidity 0.4.24;


contract OraclizeI {

    address public cbAddress;
    function setProofType(byte _proofType) external;

    function setCustomGasPrice(uint _gasPrice) external;

    function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);

    function query(uint _timestamp, string _datasource, string _arg)
        external
        payable
        returns (bytes32 _id);

    function getPrice(string _datasource) public returns (uint _dsprice);
}


contract OraclizeAddrResolverI {
    function getAddress() public returns (address _addr);
}


contract UsingOraclize {

    byte constant internal proofType_Ledger = 0x30;
    byte constant internal proofType_Android = 0x40;
    byte constant internal proofStorage_IPFS = 0x01;
    uint8 constant internal networkID_auto = 0;
    uint8 constant internal networkID_mainnet = 1;
    uint8 constant internal networkID_testnet = 2;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;

    modifier oraclizeAPI {
        if ((address(OAR) == 0)||(getCodeSize(address(OAR)) == 0))
            oraclize_setNetwork(networkID_auto);

        if (address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool) {
        return oraclize_setNetwork();
         
        networkID;  
    }

    function oraclize_setNetwork() internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0){  
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){  
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0){  
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){  
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){  
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(0, datasource, arg);
    }

    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }

    function oraclize_query(uint timestamp, string datasource, string arg)
        oraclizeAPI
        internal
        returns (bytes32 id)
    {
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }

    function oraclize_cbAddress() internal oraclizeAPI returns (address) {
        return oraclize.cbAddress();
    }

    function oraclize_setProof(byte proofP) internal oraclizeAPI {
        return oraclize.setProofType(proofP);
    }

    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }

    function getCodeSize(address _addr) internal view returns(uint _size) {
         
        assembly {
            _size := extcodesize(_addr)
        }
    }

       
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    string public oraclize_network_name;

    function oraclize_setNetworkName(string _networkName) internal {
        oraclize_network_name = _networkName;
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

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint256 a, uint256 power) internal pure returns (uint256 result) {
        assert(a >= 0);
        result = 1;
        for (uint256 i = 0; i < power; i++) {
            result *= a;
            assert(result >= a);
        }
    }
}


 
contract Ownable {

    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


 
contract Accessable is Ownable {

    uint256 public billingPeriod = 28 days;

    uint256 public oneTimePrice = 200 szabo;

    uint256 public billingAmount = 144 finney;

    mapping(address => uint256) public access;

    event AccessGranted(address addr, uint256 expired);

     
    modifier onlyPayed() {
        require(access[msg.sender] > now || msg.value == oneTimePrice);
        _;
    }

    function () external payable {
        processPurchase(msg.sender);
    }

     
    function setOneTimePrice(uint256 _priceInWei) external onlyOwner {
        require(_priceInWei < 2000 szabo);
        oneTimePrice = _priceInWei;
    }

    function setbillingAmount(uint256 _priceInWei) external onlyOwner {
        require(_priceInWei < oneTimePrice * 24 * billingPeriod);
        billingAmount = _priceInWei;
    }

    function hasAccess(address _who) external returns(bool) {
        return access[_who] > now;
    }

    function processPurchase(address _beneficiary) public payable {
        require(_beneficiary != address(0));
        uint256 _units = msg.value / billingAmount;
        require(_units > 0);
        uint256 _remainder = msg.value % billingAmount;
        _beneficiary.transfer(_remainder);
        grantAccess(_beneficiary, _units);
    }

     
    function grantAccess(address _addr, uint256 _periods) internal {
        uint256 _accessExpTime;
        if (access[_addr] < now) {
            _accessExpTime = now + billingPeriod * _periods;
        } else {
            _accessExpTime = _accessExpTime + billingPeriod * _periods;
        }
        access[_addr] = _accessExpTime;
        emit AccessGranted(_addr, _accessExpTime);
    }
}


contract Reoraclizer is UsingOraclize, Accessable {
    using SafeMath for uint256;

    uint256 public lastTimeUpdate;
    uint256 minUpdatePeriod = 3300;  

    string internal response;  

    uint256 internal CALLBACK_GAS_LIMIT = 115000;

     
     
    uint256 internal price = 999999;

    event NewOraclizeQuery(string description);

    constructor() public {
        oraclize_setProof(proofType_Android | proofStorage_IPFS);
        oraclize_setCustomGasPrice(10000000000);
    }

     
    function __callback(bytes32 _myid, string _result, bytes _proof) public {
        require((lastTimeUpdate + minUpdatePeriod) < now);
        if (msg.sender != oraclize_cbAddress()) revert();

        price = parseInt(_result, 4);
        lastTimeUpdate = now;

        _update(3600);
    }

    function getEthUsdPrice() external onlyPayed payable returns(uint256) {
        return price;
    }

     
    function _update(uint256 _timeout) internal {
        oraclize_query(_timeout, "URL", "json(https://api.coinmarketcap.com/v2/ticker/1027).data.quotes.USD.price", CALLBACK_GAS_LIMIT);
    }

    function update(uint256 _timeout) public payable onlyOwner {
        _update(_timeout);
    }

    function setOraclizeGasLimit (uint256 _gasLimit) external onlyOwner {
        CALLBACK_GAS_LIMIT = _gasLimit;
    }

    function setGasPrice(uint256 _gasPrice) external onlyOwner {
        oraclize_setCustomGasPrice(_gasPrice);
    }

    function withdrawEth(uint256 _value) external onlyOwner {
        require(address(this).balance > _value.add(3 ether));
        owner.transfer(_value);
    }

    function setMinUpdatePeriod(uint256 _minUpdatePeriod) external onlyOwner {
        minUpdatePeriod = _minUpdatePeriod;
    }
}