 

 
 

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) returns (bytes32 _id);
    function getPrice(string _datasource) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function useCoupon(string _coupon);
    function setProofType(byte _proofType);
}
contract OraclizeAddrResolverI {
    function getAddress() returns (address _addr);
}
contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;
    
    OraclizeI oraclize;
    modifier oraclizeAPI {
        address oraclizeAddr = OAR.getAddress();
        if (oraclizeAddr == 0){
            oraclize_setNetwork(networkID_auto);
            oraclizeAddr = OAR.getAddress();
        }
        oraclize = OraclizeI(oraclizeAddr);
        _
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        oraclize.useCoupon(code);
        _
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
        if (getCodeSize(0x1d3b2638a7cc9f2cb3d298a3da7a90b67e5506ed)>0){
            OAR = OraclizeAddrResolverI(0x1d3b2638a7cc9f2cb3d298a3da7a90b67e5506ed);
            return true;
        }
        if (getCodeSize(0x9efbea6358bed926b293d2ce63a730d6d98d43dd)>0){
            OAR = OraclizeAddrResolverI(0x9efbea6358bed926b293d2ce63a730d6d98d43dd);
            return true;
        }
        if (getCodeSize(0x20e12a1f859b3feae5fb2a0a32c18f5a65555bbf)>0){
            OAR = OraclizeAddrResolverI(0x20e12a1f859b3feae5fb2a0a32c18f5a65555bbf);
            return true;
        }
        return false;
    }
    
    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }


    function parseAddr(string _a) internal returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }


    function strCompare(string _a, string _b) internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
   } 

    function indexOf(string _haystack, string _needle) internal returns (int)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
            return -1;
        else if(h.length > (2**128 -1))
            return -1;                                  
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }   
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }   
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    
    function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

     
    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

     
    function parseInt(string _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        return mint;
    }
    

}
 

contract Dice is usingOraclize {

    uint public pwin = 5000;  
    uint public edge = 200;  
    uint public maxWin = 100;  
    uint public minBet = 1 finney;
    uint public maxInvestors = 5;  
    uint public ownerEdge = 50;  
    uint public divestFee = 50;  
    
    uint constant safeGas = 25000;
    uint constant oraclizeGasLimit = 150000;

    struct Investor {
        address user;
        uint capital;
    }
    mapping(uint => Investor) investors;  
    uint public numInvestors = 0;
    mapping(address => uint) investorIDs;
    uint public invested = 0;
    
    address owner;
    bool public isStopped;

    struct Bet {
        address user;
        uint bet;  
        uint roll;  
	uint fee; 
    }
    mapping (bytes32 => Bet) bets;
    bytes32[] betsKeys;
    uint public amountWagered = 0;
    int public profit = 0;
    int public takenProfit = 0;
    int public ownerProfit = 0;

    function Dice(uint pwinInitial, uint edgeInitial, uint maxWinInitial, uint minBetInitial, uint maxInvestorsInitial, uint ownerEdgeInitial, uint divestFeeInitial) {
        
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        
        pwin = pwinInitial;
        edge = edgeInitial;
        maxWin = maxWinInitial;
        minBet = minBetInitial;
        maxInvestors = maxInvestorsInitial;
        ownerEdge = ownerEdgeInitial;
        divestFee = divestFeeInitial;
        
        owner = msg.sender;
    }


    function() {
        bet();
    }

    function bet() {
        if (isStopped) throw;
        uint oraclizeFee = OraclizeI(OAR.getAddress()).getPrice("URL", oraclizeGasLimit);
        if (msg.value < oraclizeFee) throw;
        uint betValue = msg.value - oraclizeFee;
        if ((((betValue * ((10000 - edge) - pwin)) / pwin ) <= (maxWin * getBankroll()) / 10000) && (betValue >= minBet)) {
            bytes32 myid = oraclize_query("URL", "json(https://api.random.org/json-rpc/1/invoke).result.random.data.0", 'BDXJhrVpBJ53o2CxlJRlQtZJKZqLYt5IQe+73YDS4HtNjS5HodbIB3tvfow7UquyAk085VkLnL9EpKgwqWQz7ZLdGvsQlRd2sKxIolNg9DbnfPspGqLhLbbYSVnN8CwvsjpAXcSSo3c+4cNwC90yF4oNibkvD3ytapoZ7goTSyoUYTfwSjnw3ti+HJVH7N3+c0iwOCqZjDdsGQUcX3m3S/IHWbOOQQ5osO4Lbj3Gg0x1UdNtfUzYCFY79nzYgWIQEFCuRBI0n6NBvBQW727+OsDRY0J/9/gjt8ucibHWic0=', oraclizeGasLimit); // encrypted arg: '\n{"jsonrpc":2.0,"method":"generateSignedIntegers","params":{"apiKey":"YOUR_API_KEY","n":1,"min":1,"max":10000},"id":1}'
            bets[myid] = Bet(msg.sender, betValue, 0, oraclizeFee);
            betsKeys.push(myid);
        } else {
            throw;  
        }
    }

    function numBets() constant returns(uint) {
        return betsKeys.length;
    }
    
    function minBetAmount() constant returns(uint) {
        uint oraclizeFee = OraclizeI(OAR.getAddress()).getPrice("URL", oraclizeGasLimit);
        return oraclizeFee+minBet;
    }
    
    function safeSend(address addr, uint value) internal {
        if (!(addr.call.gas(safeGas).value(value)())){
            ownerProfit += int(value);
        }
    }
  
    function __callback(bytes32 myid, string result, bytes proof) {
        if (msg.sender != oraclize_cbAddress()) throw;
        
        Bet thisBet = bets[myid];
        if (thisBet.bet>0) {
            if ((isStopped == false)&&(((thisBet.bet * ((10000 - edge) - pwin)) / pwin ) <= maxWin * getBankroll() / 10000)) {
                uint roll = parseInt(result);
                if (roll<1 || roll>10000){
                    safeSend(thisBet.user, thisBet.bet);
                    return;    
                }

                bets[myid].roll = roll;
                
                int profitDiff;
                if (roll-1 < pwin) {  
                    uint winAmount = (thisBet.bet * (10000 - edge)) / pwin;
                    safeSend(thisBet.user, winAmount);
                    profitDiff = int(thisBet.bet - winAmount);
                } else {  
                    safeSend(thisBet.user, 1);
                    profitDiff = int(thisBet.bet) - 1;
                }
                
                ownerProfit += (profitDiff*int(ownerEdge))/10000;
                profit += profitDiff-(profitDiff*int(ownerEdge))/10000;
                
                amountWagered += thisBet.bet;
            } else {
                 
                safeSend(thisBet.user, thisBet.bet);
            }
        }
    }

    function getBet(uint id) constant returns(address, uint, uint, uint) {
        if(id<betsKeys.length)
        {
            bytes32 betKey = betsKeys[id];
            return (bets[betKey].user, bets[betKey].bet, bets[betKey].roll, bets[betKey].fee);
        }
    }

    function invest() {
        if (isStopped) throw;
        
        if (investorIDs[msg.sender]>0) {
            rebalance();
            investors[investorIDs[msg.sender]].capital += msg.value;
            invested += msg.value;
        } else {
            rebalance();
            uint investorID = 0;
            if (numInvestors<maxInvestors) {
                investorID = ++numInvestors;
            } else {
                for (uint i=1; i<=numInvestors; i++) {
                    if (investors[i].capital<msg.value && (investorID==0 || investors[i].capital<investors[investorID].capital)) {
                        investorID = i;
                    }
                }
            }
            if (investorID>0) {
                if (investors[investorID].capital>0) {
                    divest(investors[investorID].user, investors[investorID].capital);
                    investorIDs[investors[investorID].user] = 0;
                }
                if (investors[investorID].capital == 0 && investorIDs[investors[investorID].user] == 0) {
                    investors[investorID].user = msg.sender;
                    investors[investorID].capital = msg.value;
                    invested += msg.value;
                    investorIDs[msg.sender] = investorID;
                } else {
                    throw;
                }
            } else {
                throw;
            }
        }
    }

    function rebalance() private {
        if (takenProfit != profit) {
            uint newInvested = 0;
            uint initialBankroll = getBankroll();
            for (uint i=1; i<=numInvestors; i++) {
                investors[i].capital = getBalance(investors[i].user);
                newInvested += investors[i].capital;
            }
            invested = newInvested;
            if (newInvested != initialBankroll && numInvestors>0) {
                ownerProfit += int(initialBankroll - newInvested);  
                invested += (initialBankroll - newInvested);
            }
            takenProfit = profit;
        }
    }

    function divest(address user, uint amount) private {
        if (investorIDs[user]>0) {
            rebalance();
            if (amount>getBalance(user)) {
                amount = getBalance(user);
            }
            investors[investorIDs[user]].capital -= amount;
            invested -= amount;
            
            uint newAmount = (amount*divestFee)/10000;  
            ownerProfit += int(newAmount);
            safeSend(user, (amount-newAmount));
        }
    }

    function divest(uint amount) {
        if (msg.value>0) throw;
        divest(msg.sender, amount);
    }

    function divest() {
        if (msg.value>0) throw;
        divest(msg.sender, getBalance(msg.sender));
    }

    function getBalance(address user) constant returns(uint) {
        if (investorIDs[user]>0 && invested>0) {
            return investors[investorIDs[user]].capital * getBankroll() / invested;
        } else {
            return 0;
        }
    }

    function getBankroll() constant returns(uint) {
        uint bankroll = uint(int(invested)+profit+ownerProfit-takenProfit);
        if (this.balance < bankroll){
            log0("bankroll_mismatch");
            bankroll = this.balance;
        }
        return bankroll;
    }

    function getMinInvestment() constant returns(uint) {
        if (numInvestors<maxInvestors) {
            return 0;
        } else {
            uint investorID;
            for (uint i=1; i<=numInvestors; i++) {
                if (investorID==0 || getBalance(investors[i].user)<getBalance(investors[investorID].user)) {
                    investorID = i;
                }
            }
            return getBalance(investors[investorID].user);
        }
    }

    function getStatus() constant returns(uint, uint, uint, uint, uint, uint, int, uint, uint) {
        return (getBankroll(), pwin, edge, maxWin, minBet, amountWagered, profit, getMinInvestment(), betsKeys.length);
    }

    function stopContract() {
        if (owner != msg.sender) throw;
        isStopped = true;
    }
  
    function resumeContract() {
        if (owner != msg.sender) throw;
        isStopped = false;
    }
    
    function forceDivestAll() {
        forceDivestAll(false);
    }
    
    function forceDivestAll(bool ownerTakeChangeAndProfit) {
        if (owner != msg.sender) throw;
        for (uint investorID=1; investorID<=numInvestors; investorID++) {
            divest(investors[investorID].user, getBalance(investors[investorID].user));
        }
        if (ownerTakeChangeAndProfit) owner.send(this.balance);
    }
    
    function ownerTakeProfit() {
        ownerTakeProfit(false);
    }
    
    function ownerTakeProfit(bool takeChange) {
        if (owner != msg.sender) throw;
        if (takeChange){
            uint investorsCapital = 0;
            for (uint i=1; i<=numInvestors; i++) {
                investorsCapital += investors[i].capital;
            }
            if ((investorsCapital == 0)&&(this.balance != uint(ownerProfit))){
                owner.send(this.balance);
                ownerProfit = 0;
            }
        } else {
            owner.send(uint(ownerProfit));
            ownerProfit = 0;
        }
    }
   
}