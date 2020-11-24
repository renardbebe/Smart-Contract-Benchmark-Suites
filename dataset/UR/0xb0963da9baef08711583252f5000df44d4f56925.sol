 

pragma solidity 0.4.24;
 

library SafeMath {
  function mul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) pure internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function abs128(int128 a) internal pure returns (int128) {
    return a < 0 ? a * -1 : a;
  }
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
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

 
contract Token {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
}

 
contract Reclaimable is Ownable {

     
    constructor() public payable {
    }

     
    function() public payable {
    }

     
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function reclaimToken(address _token) public onlyOwner {
        Token token = Token(_token);

        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }
}

 
 
 
 
 



contract Storage is Ownable, Reclaimable {
    using SafeMath for uint256;

    uint256 maxGasPrice = 4000000000;
    uint256 public gasrequest = 250000;

    uint256[] public time;
    int256[] public amount;
    address[] public investorsAddresses;

    int256 public aum; 
    uint256 public decimals = 8;
    mapping(uint256 => bool) public timeExists;
    mapping (address => bool) public resellers;
    mapping (address => bool) public investors;
    mapping (address => mapping (address => bool)) resinv;

    mapping(address => uint256) public ntx;
    mapping(address => uint256) public rtx;

    mapping ( address => mapping (uint256 => btcTransaction)) public fundTx;
    mapping ( address => mapping (uint256 => btcTransactionRequest)) public reqWD;

    uint256 public btcPrice;
    uint256 public fee1;
    uint256 public fee2;
    uint256 public fee3;

     
    uint256 public fundDepositAddressesLength;
    mapping (uint256 => string) public fundDepositAddresses;


    uint256 public feeAddressesLength;
    mapping (uint256 => string) public feeAddresses;

     
    struct btcTransaction {
        string txId;
        string pubKey;
        string signature;
         
        uint256 action;
        uint256 timestamp;
    }

     
 
    struct btcTransactionRequest {
        string txId;
        string pubKey;
        string signature;
        uint256 action;  
        uint256 timestamp;
        string referal;
    }

	constructor () public {

	}
     

    function setfundDepositAddress(string bitcoinAddress) public onlyOwner {
         
        fundDepositAddresses[fundDepositAddressesLength++] = bitcoinAddress;
    }

    function setFeeAddress(string bitcoinAddress) public onlyOwner {
         
        feeAddresses[feeAddressesLength++] = bitcoinAddress;
    }

     

    function setRequestGas (uint256 _gasrequest) public onlyOwner{
        gasrequest = _gasrequest;
    }

    function setAum(int256 _aum) public onlyOwner{
        aum = _aum;
    }


    function depositAdmin(address addr,string txid, string pubkey, string signature) public onlyOwner{
        setInvestor(addr, true);
        addTX (addr,txid, pubkey, signature, 0); 
    
        uint256 gasPrice = tx.gasprice;
        uint256 repayal = gasPrice.mul(gasrequest);
        addr.transfer(repayal);
    }

     

     
    function requesWithdraw(address addr,string txid, string pubkey, string signature, string referal) public {
        require(investors[msg.sender]==true);

        uint256 i =  rtx[addr];
        reqWD[addr][i].txId=txid;
        reqWD[addr][i].pubKey=pubkey;
        reqWD[addr][i].signature=signature;
        reqWD[addr][i].action=1;
        reqWD[addr][i].timestamp = block.timestamp;
        reqWD[addr][i].referal = referal;
        ++rtx[addr];
    }

    function returnInvestment(address addr,string txid, string pubkey, string signature) public onlyOwner {
         
        addTX (addr,txid, pubkey, signature, 1);
    }

     

    function setInvestor(address _addr, bool _allowed) public onlyOwner {
        investors[_addr] = _allowed;
        if(_allowed != false){
            uint256 hasTransactions= ntx[_addr];
            if(hasTransactions == 0){
                investorsAddresses.push(_addr);
            }
        }
    }

    function getAllInvestors() public view returns (address[]){
        return investorsAddresses;
    }

     

    function setReseller(address _addr, bool _allowed) public onlyOwner {
        resellers[_addr] = _allowed;
    }

    function setResellerInvestor(address _res, address _inv, bool _allowed) public onlyOwner {
        resinv[_res][_inv] = _allowed;
    }

     

     
    function addTX (address addr,string txid, string pubkey, string signature, uint256 action) internal {
        uint256 i =  ntx[addr];
        fundTx[addr][i].txId = txid;
        fundTx[addr][i].pubKey = pubkey;
        fundTx[addr][i].signature = signature;
        fundTx[addr][i].action = action;
        fundTx[addr][i].timestamp = block.timestamp;
        ++ntx[addr];
    }

    function getTx (address addr, uint256 i) public view returns (string,string,string,uint256, uint256) {
        return (fundTx[addr][i].txId,fundTx[addr][i].pubKey,fundTx[addr][i].signature,fundTx[addr][i].action, fundTx[addr][i].timestamp);
    }

    function setData(uint256 t, int256 a) public onlyOwner{
        require(timeExists[t] != true);
        time.push(t);
        amount.push(a);
        timeExists[t] = true;
    }

    function setDataBlock(int256 a) public onlyOwner{
        require(timeExists[block.timestamp] != true);
        time.push(block.timestamp);
        amount.push(a);
        timeExists[block.timestamp] = true;
    }

    function getAll() public view returns(uint256[] t, int256[] a){
        return (time, amount);
    }

    function setBtcPrice(uint256 _price) public onlyOwner {
        btcPrice = _price;
    }

    
    function setFee(uint256 _fee1,uint256 _fee2,uint256 _fee3) public onlyOwner {
        fee1 = _fee1;
        fee2 = _fee2;
        fee3 = _fee3;
    }
}