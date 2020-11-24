 

pragma solidity ^0.4.24;

 

contract SixFriends {

    using SafeMath for uint;

    address public ownerAddress;  
    uint private percentMarketing = 8;  
    uint private percentAdministrator = 2;  

    uint public c_total_hexagons;  
    mapping(address =>  uint256) public Bills;  

    uint256 public BillsTotal;  

    struct Node {
        uint256 usd;
        bool cfw;
        uint256 min;  
        uint c_hexagons;  
        mapping(address => bytes32[]) Addresses;  
        mapping(address => uint256[6]) Statistics;  
        mapping(bytes32 => address[6]) Hexagons;  
    }

    mapping (uint256 => Node) public Nodes;  

     
    modifier enoughMoney(uint256 tp) {
        require (msg.value >= Nodes[0].min, "Insufficient funds");
        _;
    }

     
    modifier onlyOwner {
        require (msg.sender == ownerAddress, "Only owner");
        _;
    }

     
    modifier allReadyCreate(uint256 tp) {
        require (Nodes[tp].cfw == false);
        _;
    }

     
    modifier recipientOwner(address recipient) {
        require (Bills[recipient] > 0);
        require (msg.sender == recipient);
        _;
    }

     
    function pay(bytes32 ref, uint256 tp) public payable enoughMoney(tp) {

        if (Nodes[tp].Hexagons[ref][0] == 0) ref = Nodes[tp].Addresses[ownerAddress][0];  

        createHexagons(ref, tp);  

        uint256 marketing_pay = ((msg.value / 100) * (percentMarketing + percentAdministrator));
        uint256 friend_pay = msg.value - marketing_pay;

         
        for(uint256 i = 0; i < 6; i++)
            Bills[Nodes[tp].Hexagons[ref][i]] += friend_pay.div(6);

         
        Bills[ownerAddress] += marketing_pay;

         
        BillsTotal += msg.value;
    }

    function getHexagons(bytes32 ref, uint256 tp) public view returns (address, address, address, address, address, address)
    {
        return (Nodes[tp].Hexagons[ref][0], Nodes[tp].Hexagons[ref][1], Nodes[tp].Hexagons[ref][2], Nodes[tp].Hexagons[ref][3], Nodes[tp].Hexagons[ref][4], Nodes[tp].Hexagons[ref][0]);
    }

     
    function getMoney(address recipient) public recipientOwner(recipient) {
        recipient.transfer(Bills[recipient]);
        Bills[recipient] = 0;
    }

     
    function createHexagons(bytes32 ref, uint256 tp) internal {

        Nodes[tp].c_hexagons++;  
        c_total_hexagons++;  

        bytes32 new_ref = createRef(Nodes[tp].c_hexagons);

         
        for(uint8 i = 0; i < 5; i++)
        {
            Nodes[tp].Hexagons[new_ref][i] = Nodes[tp].Hexagons[ref][i + 1];  
            Nodes[tp].Statistics[Nodes[tp].Hexagons[ref][i]][5 - i]++;  
        }

        Nodes[tp].Statistics[Nodes[tp].Hexagons[ref][i]][0]++;  

        Nodes[tp].Hexagons[new_ref][5] = msg.sender;
        Nodes[tp].Addresses[msg.sender].push(new_ref);  
    }

     
    function createFirstWallets(uint256 usd, uint256 tp) public onlyOwner allReadyCreate(tp) {

        bytes32 new_ref = createRef(1);

        Nodes[tp].Hexagons[new_ref] = [ownerAddress, ownerAddress, ownerAddress, ownerAddress, ownerAddress, ownerAddress];
        Nodes[tp].Addresses[ownerAddress].push(new_ref);

        Nodes[tp].c_hexagons = 1;  
        Nodes[tp].usd = usd;  
        Nodes[tp].cfw = true;  

        c_total_hexagons++;
    }

     
    function createRef(uint hx) internal pure returns (bytes32) {
        uint256 _unixTimestamp;
        uint256 _timeExpired;
        return keccak256(abi.encodePacked(hx, _unixTimestamp, _timeExpired));
    }

     
    function countAddressRef(address adr, uint256 tp) public view returns (uint count) {
        count = Nodes[tp].Addresses[adr].length;
    }

     
    function getAddress(address adr, uint256 i, uint256 tp) public view returns(bytes32) {
        return Nodes[tp].Addresses[adr][i];
    }

     
    function getStatistics(address adr, uint256 tp) public view returns(uint256, uint256, uint256, uint256, uint256, uint256)
    {
        return (Nodes[tp].Statistics[adr][0], Nodes[tp].Statistics[adr][1], Nodes[tp].Statistics[adr][2], Nodes[tp].Statistics[adr][3], Nodes[tp].Statistics[adr][4], Nodes[tp].Statistics[adr][5]);
    }

     
    function setMin(uint value, uint256 tp) public onlyOwner {
        Nodes[tp].min = value;
    }

     
    function getMin(uint256 tp) public view returns (uint256) {
        return Nodes[tp].min;
    }

     
    function getBillsTotal() public view returns (uint256) {
        return BillsTotal;
    }

    constructor() public {
        ownerAddress = msg.sender;
    }
}

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