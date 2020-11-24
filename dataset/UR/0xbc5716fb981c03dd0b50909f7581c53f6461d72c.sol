 

pragma solidity >=0.4.22 <0.6.0;
 

contract LongHuContract {
  uint  maxProfit; 
  uint  maxmoneypercent;
  uint public contractBalance;
   
   
  uint minBet;
  uint onoff; 
  address private owner;
  uint private orderId;
  uint private randonce;

  event LogNewOraclizeQuery(string description,bytes32 queryId);
  event LogNewRandomNumber(string result,bytes32 queryId);
  event LogSendBonus(uint id,bytes32 lableId,uint playId,uint content,uint singleMoney,uint mutilple,address user,uint betTime,uint status,uint winMoney);
  event LogBet(bytes32 queryId);

  mapping (address => bytes32[]) playerLableList; 
  mapping (bytes32 => mapping (uint => uint[7])) betList; 
  mapping (bytes32 => uint) lableCount; 
  mapping (bytes32 => uint) lableTime; 
  mapping (bytes32 => uint) lableStatus; 
  mapping (bytes32 => uint[4]) openNumberList; 
  mapping (bytes32 => string) openNumberStr; 
  mapping (bytes32 => address payable) lableUser;

  bytes tempNum ;  
  uint[] numbers;

  constructor() public {
    owner = msg.sender;
    orderId = 0;
    onoff=1;
     
     
    maxmoneypercent=80;
     
    contractBalance = address(this).balance;
    maxProfit=(address(this).balance * maxmoneypercent)/100;
     
    randonce = 0;
  }

  modifier onlyAdmin() {
      require(msg.sender == owner);
      _;
  }
   
   
   
  

  function setGameOnoff(uint _on0ff) public onlyAdmin{
    onoff=_on0ff;
  }

  function getPlayRate(uint playId,uint level) internal pure returns (uint){
      uint result = 0;
      if(playId == 1 || playId == 3){
        result = 19; 
      }else if(playId == 2){
        result = 9;
      }
      return result;
    }

    function doBet(uint[] memory playid,uint[] memory betMoney,uint[] memory betContent,uint mutiply) public payable returns (bytes32 queryId) {
      require(onoff==1);
      require(playid.length > 0);
      require(mutiply > 0);
      require(msg.value >= minBet);

      checkBet(playid,betMoney,betContent,mutiply,msg.value);

       
      bytes32 queryId;
      queryId = keccak256(abi.encodePacked(blockhash(block.number-1),now,randonce));
       
       
       
       
       
       
        emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..",queryId);
       
       

       uint[7] memory tmp ;
       uint totalspand = 0;
      for(uint i=0;i<playid.length;i++){
        orderId++;
        tmp[0] =orderId;
        tmp[1] =playid[i];
        tmp[2] =betContent[i];
        tmp[3] =betMoney[i]*mutiply;
        totalspand +=betMoney[i]*mutiply;
        tmp[4] =now;
        tmp[5] =0;
        tmp[6] =0;
        betList[queryId][i] =tmp;
      }
      require(msg.value >= totalspand);

      lableTime[queryId] = now;
      lableCount[queryId] = playid.length;
      lableUser[queryId] = msg.sender;
      uint[4] memory codes = [uint(0),0,0,0];
      openNumberList[queryId] = codes;
      openNumberStr[queryId] ="0,0,0,0";
      lableStatus[queryId] = 0;

      uint index=playerLableList[msg.sender].length++;
      playerLableList[msg.sender][index]=queryId; 
      emit LogBet(queryId);
      opencode(queryId);
      return queryId;
    }

    function opencode(bytes32 queryId) private {
      if (lableCount[queryId] < 1) revert();
      uint[4] memory codes = [uint(0),0,0,0]; 

      bytes32 code0hash = keccak256(abi.encodePacked(blockhash(block.number-1), now,msg.sender,randonce));
      randonce  = randonce + uint(code0hash)%1000;
       
      codes[0] = uint(code0hash) % 52 + 1;
      string memory code0 =uint2str(uint(code0hash) % 52 + 1);

      bytes32 code1hash = keccak256(abi.encodePacked(blockhash(block.number-1), now,msg.sender,randonce));
      randonce  = randonce + uint(code1hash)%1000;
       
      codes[1] = uint(code1hash) % 52 + 1;
      string memory code1=uint2str(uint(code1hash) % 52 + 1);

      bytes32 code2hash = keccak256(abi.encodePacked(blockhash(block.number-1), now,msg.sender,randonce));
      randonce  = randonce + uint(code2hash)%1000;
       
      codes[2] = uint(code2hash) % 52 + 1;
      string memory code2=uint2str(uint(code2hash) % 52 + 1);

      bytes32 code3hash = keccak256(abi.encodePacked(blockhash(block.number-1), now,msg.sender,randonce));
      randonce  = randonce + uint(code3hash)%1000;
       
      codes[3] = uint(code3hash) % 52 + 1;
      string memory code3=uint2str(uint(code3hash) % 52 + 1);

       
       
       
       
       
       
       
       
      openNumberList[queryId] = codes;
      string memory codenum = "";
      codenum = strConcat(code0,",",code1,",",code2);
      openNumberStr[queryId] = strConcat(codenum,",",code3);
       
      doCheckBounds(queryId);
    }

    function checkBet(uint[] memory playid,uint[] memory betMoney,uint[] memory betContent,uint mutiply,uint betTotal) internal{
        uint totalMoney = 0;
      uint totalWin1 = 0;
      uint totalWin2 = 0;
      uint rate;
      uint i;
      for(i=0;i<playid.length;i++){
        if(playid[i] >=1 && playid[i]<= 3){
          totalMoney += betMoney[i] * mutiply;
        }else{
          revert();
        }
        if(playid[i] ==1 || playid[i] ==3){ 
          rate = getPlayRate(playid[i],0);
          totalWin1+=betMoney[i] * mutiply *rate/10;
          totalWin2+=betMoney[i] * mutiply *rate/10;
        }else if(playid[i] ==2){ 
          rate = getPlayRate(playid[i],0);
          totalWin2+=betMoney[i] * mutiply *rate;
        }
      }
      uint maxWin=totalWin1;
      if(totalWin2 > maxWin){
        maxWin=totalWin2;
      }
      require(betTotal >= totalMoney);

      require(maxWin < maxProfit);
    }
     
    function doCancel(bytes32 queryId) internal {
      uint sta = lableStatus[queryId];
      require(sta == 0);
      uint[4] memory codes = openNumberList[queryId];
      require(codes[0] == 0 || codes[1] == 0 ||codes[2] == 0 ||codes[3] == 0);

      uint totalBet = 0;
      uint len = lableCount[queryId];

      address payable to = lableUser[queryId];
      for(uint aa = 0 ; aa<len; aa++){
         
        if(betList[queryId][aa][5] == 0){
          totalBet+=betList[queryId][aa][3];
        }
      }

      if(totalBet > 0){
        to.transfer(totalBet);
      }
      contractBalance=address(this).balance;
      maxProfit=(address(this).balance * maxmoneypercent)/100;
      lableStatus[queryId] = 1;
    }

    function doSendBounds(bytes32 queryId) public payable {
      uint sta = lableStatus[queryId];
      require(sta == 2);

      uint totalWin = 0;
      uint len = lableCount[queryId];

      address payable to = lableUser[queryId];
      for(uint aa = 0 ; aa<len; aa++){
         
        if(betList[queryId][aa][5] == 2){
          totalWin+=betList[queryId][aa][6];
        }
      }

      if(totalWin > 0){
          to.transfer(totalWin); 
      }
      lableStatus[queryId] = 3;
      contractBalance=address(this).balance;
      maxProfit=(address(this).balance * maxmoneypercent)/100;
    }

     
    function checkWinMoney(uint[7] storage betinfo,uint[4] memory codes) internal {
      uint rates;
      uint code0 = codes[0]%13==0?13:codes[0]%13;
      uint code1 = codes[1]%13==0?13:codes[1]%13;
      uint code2 = codes[2]%13==0?13:codes[2]%13;
      uint code3 = codes[3]%13==0?13:codes[3]%13;
      uint  onecount = code0 + code2;
      uint  twocount = code1 + code3;
      onecount = onecount%10;
      twocount = twocount%10;
      if(betinfo[1] ==1){ 
          if(onecount > twocount){
              betinfo[5]=2;
              rates = getPlayRate(betinfo[1],0);
              betinfo[6]=betinfo[3]*rates/10;
          }else{
              
              
              
              
              
                  betinfo[5]=1;
              
          }
      }else if(betinfo[1] == 2){ 
          if(onecount == twocount){
            betinfo[5]=2;
            rates = getPlayRate(betinfo[1],0);
            betinfo[6]=betinfo[3]*rates;
          }else{
            betinfo[5]=1;
          }

        }else if(betinfo[1] == 3){ 
          betinfo[5]=1;
          if(onecount < twocount ){
            betinfo[5]=2;
            rates = getPlayRate(betinfo[1],0);
            betinfo[6]=betinfo[3]*rates/10;
          }else{
               
               
               
               
              
                  betinfo[5]=1;
              
          }
        }

    }

    function getLastBet() public view returns(string memory opennum,uint[7][] memory result){
      uint len=playerLableList[msg.sender].length;
      require(len>0);

      uint i=len-1;
      bytes32 lastLable = playerLableList[msg.sender][i];
      uint max = lableCount[lastLable];
      if(max > 50){
          max = 50;
      }
      uint[7][] memory result = new uint[7][](max) ;
      string memory opennum = "";
      for(uint a=0;a<max;a++){
         string memory ttmp =openNumberStr[lastLable];
         if(a==0){
           opennum =ttmp;
         }else{
           opennum = strConcat(opennum,";",ttmp);
         }

         result[a] = betList[lastLable][a];
         if(lableStatus[lastLable] == 1){
           result[a][5]=3;
         }

      }

      return (opennum,result);
    }

    function getLableRecords(bytes32 lable) public view returns(string memory opennum,uint[7][] memory result){
      uint max = lableCount[lable];
      if(max > 50){
          max = 50;
      }
      uint[7][] memory result = new uint[7][](max) ;
      string memory opennum="";

      for(uint a=0;a<max;a++){
         result[a] = betList[lable][a];
         if(lableStatus[lable] == 1){
           result[a][5]=3;
         }
         string memory ttmp =openNumberStr[lable];
         if(a==0){
           opennum =ttmp;
         }else{
           opennum = strConcat(opennum,";",ttmp);
         }
      }

      return (opennum,result);
    }

    function getAllRecords() public view returns(string  memory opennum,uint[7][] memory result){
        uint len=playerLableList[msg.sender].length;
        require(len>0);

        uint max;
        bytes32 lastLable ;
        uint ss;

        for(uint i1=0;i1<len;i1++){
            ss = len-i1-1;
            lastLable = playerLableList[msg.sender][ss];
            max += lableCount[lastLable];
            if(100 < max){
              max = 100;
              break;
            }
        }

        uint[7][] memory result = new uint[7][](max) ;
        bytes32[] memory resultlable = new bytes32[](max) ;
        string memory opennum="";

        bool flag=false;
        uint betnums;
        uint j=0;

        for(uint ii=0;ii<len;ii++){
            ss = len-ii-1;
            lastLable = playerLableList[msg.sender][ss];
            betnums = lableCount[lastLable];
            for(uint k= 0; k<betnums; k++){
              if(j<max){
                  resultlable[j] = lastLable;
              	 string memory ttmp =openNumberStr[lastLable];
                 if(j==0){
                   opennum =ttmp;
                 }else{
                   opennum = strConcat(opennum,";",ttmp);
                 }
                  result[j] = betList[lastLable][k];
                  if(lableStatus[lastLable] == 1){
                    result[j][5]=3;
                  }else if(lableStatus[lastLable] == 2){
                    if(result[j][5]==2){
                      result[j][5]=4;
                    }
                  }else if(lableStatus[lastLable] == 3){
                    if(result[j][5]==2){
                      result[j][5]=5;
                    }
                  }
                  j++;
              }else{
                flag = true;
                break;
              }
            }
            if(flag){
                break;
            }
        }
        return (opennum,result);
    }

   
   
   
   
   
   

  function senttest() public payable onlyAdmin{
      contractBalance=address(this).balance;
      maxProfit=(address(this).balance*maxmoneypercent)/100;
  }

  function withdraw(uint _amount , address payable desaccount) public onlyAdmin{
      desaccount.transfer(_amount);
      contractBalance=address(this).balance;
      maxProfit=(address(this).balance * maxmoneypercent)/100;
  }

  function deposit() public payable onlyAdmin returns(uint8 ret){
      contractBalance=address(this).balance;
      maxProfit=(address(this).balance * maxmoneypercent)/100;
      ret = 1;
  }

  function getDatas() public view returns(
    uint _maxProfit,
    uint _minBet,
    uint _contractbalance,
    uint _onoff,
    address _owner,
    uint _oraclizeFee
    ){
        _maxProfit=maxProfit;
        _minBet=minBet;
        _contractbalance=contractBalance;
        _onoff=onoff;
        _owner=owner;
        
    }

    function getLableList() public view returns(string memory opennum,bytes32[] memory lablelist,uint[] memory labletime,uint[] memory lablestatus,uint){
      uint len=playerLableList[msg.sender].length;
      require(len>0);

      uint max=50;
      if(len < 50){
          max = len;
      }

      bytes32[] memory lablelist = new bytes32[](max) ;
      uint[] memory labletime = new uint[](max) ;
      uint[] memory lablestatus = new uint[](max) ;
      string memory opennum="";

      bytes32 lastLable ;
      for(uint i=0;i<max;i++){
          lastLable = playerLableList[msg.sender][max-i-1];
          lablelist[i]=lastLable;
          labletime[i]=lableTime[lastLable];
          lablestatus[i]=lableStatus[lastLable];
          string memory ttmp =openNumberStr[lastLable];
         if(i==0){
           opennum =ttmp;
         }else{
           opennum = strConcat(opennum,";",ttmp);
         }
      }

      return (opennum,lablelist,labletime,lablestatus,now);
    }

    function doCheckBounds(bytes32 queryId) internal{
        uint sta = lableStatus[queryId];
        require(sta == 0 || sta == 2);
        uint[4] memory codes = openNumberList[queryId];
        require(codes[0] > 0);

        uint len = lableCount[queryId];

        uint totalWin;
        address payable to = lableUser[queryId];
        for(uint aa = 0 ; aa<len; aa++){
          if(sta == 0){
           if(betList[queryId][aa][5] == 0){
             checkWinMoney(betList[queryId][aa],codes);
             totalWin+=betList[queryId][aa][6];
           }
          }else if(sta == 2){
              totalWin+=betList[queryId][aa][6];
          }
        }

        lableStatus[queryId] = 2;

        if(totalWin > 0){
          if(totalWin < address(this).balance){
            to.transfer(totalWin);
            lableStatus[queryId] = 3;
          }else{
              emit LogNewOraclizeQuery("sent bouns fail.",queryId);
          }
        }else{
          lableStatus[queryId] = 3;
        }
        contractBalance=address(this).balance;
        maxProfit=(address(this).balance * maxmoneypercent)/100;
    }

    function getOpenNum(bytes32 queryId) public view returns(string memory result){
        result = openNumberStr[queryId];
         
    }

    function doCheckSendBounds() public payable{
        uint len=playerLableList[msg.sender].length;

      uint max=50;
      if(len < 50){
          max = len;
      }

      uint sta;
      bytes32 lastLable ;
      for(uint i=0;i<max;i++){
          lastLable = playerLableList[msg.sender][max-i-1];
          sta = lableStatus[lastLable];
          if(sta == 0 || sta==2){
            doCheckBounds(lastLable);
          }
      }
    }

    function doCancelAll() public payable{
        uint len=playerLableList[msg.sender].length;

      uint max=50;
      if(len < 50){
          max = len;
      }

      uint sta;
      uint bettime;
      bytes32 lastLable ;
      for(uint i=0;i<max;i++){
          lastLable = playerLableList[msg.sender][max-i-1];
          sta = lableStatus[lastLable];
          bettime = lableTime[lastLable];
          if(sta == 0 && (now - bettime)>600){
            doCancel(lastLable);
          }
      }
    }

    function splitStr(string memory str, string memory delimiter) internal returns (uint [] memory){  
     bytes memory b = bytes(str);  
     bytes memory delm = bytes(delimiter);
     delete(numbers);
     delete(tempNum);
     for(uint i; i<b.length ; i++){
     if(b[i] != delm[0]) {  
       tempNum.push(b[i]);
      }
      else {
       numbers.push(parseInt(string(tempNum)));  
       tempNum = "";  
      }
     }
     if(b[b.length-1] != delm[0]) {
      numbers.push(parseInt(string(tempNum)));
     }
     return numbers;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
     return string(bstr);
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function parseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }


    function setRandomSeed(uint _randomSeed) public payable onlyAdmin{
      randonce = _randomSeed;
    }

    function getRandomSeed() public view onlyAdmin returns(uint _randonce) {
      _randonce = randonce;
    }

}