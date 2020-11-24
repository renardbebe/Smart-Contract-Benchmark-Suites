 

pragma solidity^0.4.15;

contract EtheraffleLOT {
    function mint(address _to, uint _amt) external {}
    function transfer(address to, uint value) public {}
    function balanceOf(address who) constant public returns (uint) {}
}
contract EtheraffleICO is EtheraffleLOT {

     
    uint public constant tier0LOT = 110000 * 10 ** 6;
    uint public constant tier1LOT = 100000 * 10 ** 6;
    uint public constant tier2LOT =  90000 * 10 ** 6;
    uint public constant tier3LOT =  80000 * 10 ** 6;
     
    uint public constant bonusLOT     = 1500 * 10 ** 6;
    uint public constant bonusFreeLOT = 10;
     
    uint public constant maxWeiTier0 = 700   * 10 ** 18;
    uint public constant maxWeiTier1 = 2500  * 10 ** 18;
    uint public constant maxWeiTier2 = 7000  * 10 ** 18;
    uint public constant maxWeiTier3 = 20000 * 10 ** 18;
     
    uint public constant minWei = 25 * 10 ** 15;
     
    uint public ICOStart = 1522281600; 
    uint public tier1End = 1523491200; 
    uint public tier2End = 1525305600; 
    uint public tier3End = 1527724800; 
    uint public wdBefore = 1528934400; 
     
    uint public tier0Total;
    uint public tier1Total;
    uint public tier2Total;
    uint public tier3Total;
     
    address public etheraffle;
     
    bool public ICORunning = true;
     
    mapping (address => uint) public tier0;
    mapping (address => uint) public tier1;
    mapping (address => uint) public tier2;
    mapping (address => uint) public tier3;
     
    EtheraffleLOT LOT;
    EtheraffleLOT FreeLOT;
     
    event LogTokenDeposit(address indexed from, uint value, bytes data);
    event LogRefund(address indexed toWhom, uint amountOfEther, uint atTime);
    event LogEtherTransfer(address indexed toWhom, uint amount, uint atTime);
    event LogBonusLOTRedemption(address indexed toWhom, uint lotAmount, uint atTime);
    event LogLOTTransfer(address indexed toWhom, uint indexed inTier, uint ethAmt, uint LOTAmt, uint atTime);
     
    modifier onlyEtheraffle() {
        require(msg.sender == etheraffle);
        _;
    }
     
    modifier onlyIfRunning() {
        require(ICORunning);
        _;
    }
     
    modifier onlyIfNotRunning() {
        require(!ICORunning);
        _;
    }
     
    function EtheraffleICO() public { 
        etheraffle = 0x97f535e98cf250cdd7ff0cb9b29e4548b609a0bd;
        LOT        = EtheraffleLOT(0xAfD9473dfe8a49567872f93c1790b74Ee7D92A9F);
        FreeLOT    = EtheraffleLOT(0xc39f7bB97B31102C923DaF02bA3d1bD16424F4bb);
    }
     
    function () public payable onlyIfRunning {
         
        require
        (
            now <= tier3End &&
            msg.value >= minWei
        );
        uint numLOT = 0;
        if (now <= ICOStart) { 
             
            require(tier0Total + msg.value <= maxWeiTier0);
             
            tier0[msg.sender] += msg.value;
             
            tier0Total += msg.value;
             
            numLOT = (msg.value * tier0LOT) / (1 * 10 ** 18);
             
            LOT.transfer(msg.sender, numLOT);
             
            LogLOTTransfer(msg.sender, 0, msg.value, numLOT, now);
            return;
        } else if (now <= tier1End) { 
            require(tier1Total + msg.value <= maxWeiTier1);
            tier1[msg.sender] += msg.value;
            tier1Total += msg.value;
            numLOT = (msg.value * tier1LOT) / (1 * 10 ** 18);
            LOT.transfer(msg.sender, numLOT);
            LogLOTTransfer(msg.sender, 1, msg.value, numLOT, now);
            return;
        } else if (now <= tier2End) { 
            require(tier2Total + msg.value <= maxWeiTier2);
            tier2[msg.sender] += msg.value;
            tier2Total += msg.value;
            numLOT = (msg.value * tier2LOT) / (1 * 10 ** 18);
            LOT.transfer(msg.sender, numLOT);
            LogLOTTransfer(msg.sender, 2, msg.value, numLOT, now);
            return;
        } else { 
            require(tier3Total + msg.value <= maxWeiTier3);
            tier3[msg.sender] += msg.value;
            tier3Total += msg.value;
            numLOT = (msg.value * tier3LOT) / (1 * 10 ** 18);
            LOT.transfer(msg.sender, numLOT);
            LogLOTTransfer(msg.sender, 3, msg.value, numLOT, now);
            return;
        }
    }
     
    function redeemBonusLot() external onlyIfRunning {  
         
        require
        (
            now > tier3End &&
            now < wdBefore
        );
         
        require
        (
            tier0[msg.sender] > 1 ||
            tier1[msg.sender] > 1 ||
            tier2[msg.sender] > 1 ||
            tier3[msg.sender] > 1
        );
        uint bonusNumLOT;
         
        if(tier0[msg.sender] > 1) {
            bonusNumLOT +=
             
            ((tier1Total * bonusLOT * tier0[msg.sender]) / (tier0Total * (1 * 10 ** 18))) +
             
            ((tier2Total * bonusLOT * tier0[msg.sender]) / (tier0Total * (1 * 10 ** 18))) +
             
            ((tier3Total * bonusLOT * tier0[msg.sender]) / (tier0Total * (1 * 10 ** 18)));
             
            tier0[msg.sender] = 1;
        }
        if(tier1[msg.sender] > 1) {
            bonusNumLOT +=
            ((tier2Total * bonusLOT * tier1[msg.sender]) / (tier1Total * (1 * 10 ** 18))) +
            ((tier3Total * bonusLOT * tier1[msg.sender]) / (tier1Total * (1 * 10 ** 18)));
            tier1[msg.sender] = 1;
        }
        if(tier2[msg.sender] > 1) {
            bonusNumLOT +=
            ((tier3Total * bonusLOT * tier2[msg.sender]) / (tier2Total * (1 * 10 ** 18)));
            tier2[msg.sender] = 1;
        }
        if(tier3[msg.sender] > 1) {
            tier3[msg.sender] = 1;
        }
         
        require
        (
            tier0[msg.sender]  <= 1 &&
            tier1[msg.sender]  <= 1 &&
            tier2[msg.sender]  <= 1 &&
            tier3[msg.sender]  <= 1
        );
         
        if(bonusNumLOT > 0) {
            LOT.transfer(msg.sender, bonusNumLOT);
        }
         
        FreeLOT.mint(msg.sender, bonusFreeLOT);
         
        LogBonusLOTRedemption(msg.sender, bonusNumLOT, now);
    }
     
    function refundEther() external onlyIfNotRunning {
        uint amount;
        if(tier0[msg.sender] > 1) {
             
            amount += tier0[msg.sender];
             
            tier0[msg.sender] = 0;
        }
        if(tier1[msg.sender] > 1) {
            amount += tier1[msg.sender];
            tier1[msg.sender] = 0;
        }
        if(tier2[msg.sender] > 1) {
            amount += tier2[msg.sender];
            tier2[msg.sender] = 0;
        }
        if(tier3[msg.sender] > 1) {
            amount += tier3[msg.sender];
            tier3[msg.sender] = 0;
        }
         
        require
        (
            tier0[msg.sender] == 0 &&
            tier1[msg.sender] == 0 &&
            tier2[msg.sender] == 0 &&
            tier3[msg.sender] == 0
        );
         
        msg.sender.transfer(amount);
         
        LogRefund(msg.sender, amount, now);
        return;
    }
     
    function transferEther(uint _tier) external onlyIfRunning onlyEtheraffle {
        if(_tier == 0) {
             
            require(now > ICOStart && tier0Total > 0);
             
            etheraffle.transfer(tier0Total);
             
            LogEtherTransfer(msg.sender, tier0Total, now);
            return;
        } else if(_tier == 1) {
            require(now > tier1End && tier1Total > 0);
            etheraffle.transfer(tier1Total);
            LogEtherTransfer(msg.sender, tier1Total, now);
            return;
        } else if(_tier == 2) {
            require(now > tier2End && tier2Total > 0);
            etheraffle.transfer(tier2Total);
            LogEtherTransfer(msg.sender, tier2Total, now);
            return;
        } else if(_tier == 3) {
            require(now > tier3End && tier3Total > 0);
            etheraffle.transfer(tier3Total);
            LogEtherTransfer(msg.sender, tier3Total, now);
            return;
        } else if(_tier == 4) {
            require(now > tier3End && this.balance > 0);
            etheraffle.transfer(this.balance);
            LogEtherTransfer(msg.sender, this.balance, now);
            return;
        }
    }
     
    function transferLOT() onlyEtheraffle onlyIfRunning external {
        require(now > wdBefore);
        uint amt = LOT.balanceOf(this);
        LOT.transfer(etheraffle, amt);
        LogLOTTransfer(msg.sender, 5, 0, amt, now);
    }
     
    function setCrowdSaleStatus(bool _status) external onlyEtheraffle {
        ICORunning = _status;
    }
     
    function tokenFallback(address _from, uint _value, bytes _data) public {
        if (_value > 0) {
            LogTokenDeposit(_from, _value, _data);
        }
    }
     
    function selfDestruct() external onlyIfNotRunning onlyEtheraffle {
        selfdestruct(etheraffle);
    }
}