 

pragma solidity >=0.5.8;
 

contract manekio {

   
  event playerBet (
    address indexed playerAddress,
    uint256 pick,
    uint256 eth
    );
     
    modifier onlyAdministrator(){
      address _playerAddress = msg.sender;
      require(_playerAddress == admin);
      _;
    }
     
    struct playerJBook {
      uint256 sShare;
      uint256 eShare;
    }
    struct playerBook {
      uint256 share;
      bool paid;
    }
    struct pickBook {
      uint256 share;  
      uint256 nBet;  
    }

     
    mapping(address => mapping(uint256 => playerJBook)) internal plyrJBk;  
    mapping(address => mapping(uint256 => playerBook)) internal pAddrxBk;  
    mapping(uint256 => pickBook) internal pBk;  
    uint256 internal tShare = 0;
    uint256 internal pot = 0;
    uint256 internal comm = 0;
    uint256 internal commrate = 25;
    uint256 internal commPaid = 0;
    uint256 internal jackpot = 0;
    uint256 internal jpotrate = 25;
    uint256 internal jpotinterval = 6000;
    bool internal ended = false;
    address payable internal admin = 0xe7Cef4D90BdA19A6e2A20F12A1A6C394230d2924;
     
    uint256 internal endtime = 0;
    bool internal started = false;
    uint256 internal pcknum;  
     
    uint256 internal wPck = 999;  
    uint256 internal shareval = 0;
    uint256 internal endblock = 0;  
    uint256 internal jendblock = 0;
    uint256 internal endblockhash = 0;
    address payable internal jPotWinner;
    bool internal jPotclaimed = false;

     
     
    function() external payable {
      require(msg.value > 0);
      playerPick(pcknum + 1);
    }
     
     
    function playerPick(uint256 _pck) public payable {
      address payable _pAddr = msg.sender;
      uint256 _eth = msg.value;
      require(_eth > 0 && _pck >= 0 && _pck < 999);
       
      if (_eth >= 1e16 && !checkTime() && !ended && _pck <= pcknum && started) {
         
        uint256 _commEth = _eth / commrate;
        uint256 _jpEth = _eth / jpotrate;
        comm += _commEth;
        jackpot += _jpEth;
        uint256 _potEth = _eth - _commEth - _jpEth;
         
        pot += _potEth;
         
        uint256 _share = _potEth / 1e13;
         
        pBk[_pck].nBet += 1;
        pBk[_pck].share += _share;
         
        for(uint256 i = 0; true; i++) {
          if(plyrJBk[_pAddr][i].eShare == 0){
            plyrJBk[_pAddr][i].sShare = tShare;
            plyrJBk[_pAddr][i].eShare = tShare + _share - 1;
            break;
          }
        }
         
        tShare += _share;
         
        pAddrxBk[_pAddr][_pck].share += _share;
         
        emit playerBet(_pAddr, _pck, _potEth);
      }
       
      else if (!started || !ended) {
        uint256 _commEth = _eth / commrate;
        uint256 _jpEth = _eth / jpotrate;
        comm += _commEth;
        jackpot += _jpEth;
        uint256 _potEth = _eth - _commEth - _jpEth;
        pot += _potEth;
      }
       
      else {
        comm += _eth;
      }
    }

    function claimJackpot() public {
      address payable _pAddr = msg.sender;
      uint256 _jackpot = jackpot;
      require(ended == true && checkJPotWinner(_pAddr) && !jPotclaimed);
      _pAddr.transfer(_jackpot);
      jPotclaimed = true;
      jPotWinner = _pAddr;
    }

    function payMeBitch(uint256 _pck) public {
      address payable _pAddr = msg.sender;
      require(_pck >= 0 && _pck < 998);
      require(ended == true && pAddrxBk[_pAddr][_pck].paid == false && pAddrxBk[_pAddr][_pck].share > 0 && wPck == _pck);
      _pAddr.transfer(pAddrxBk[_pAddr][_pck].share * shareval);
      pAddrxBk[_pAddr][_pck].paid = true;
    }

     
    function checkJPotWinner(address payable _pAddr) public view returns(bool){
      uint256 _endblockhash = endblockhash;
      uint256 _tShare = tShare;
      uint256 _nend = nextJPot();
      uint256 _wnum;
      require(plyrJBk[_pAddr][0].eShare != 0);
      if (jPotclaimed == true) {
        return(false);
      }
      _endblockhash = uint256(keccak256(abi.encodePacked(_endblockhash + _nend)));
      _wnum = (_endblockhash % _tShare);
      for(uint256 i = 0; true; i++) {
        if(plyrJBk[_pAddr][i].eShare == 0){
          break;
        }
        else {
          if (plyrJBk[_pAddr][i].sShare <= _wnum && plyrJBk[_pAddr][i].eShare >= _wnum ){
            return(true);
          }
        }
      }
      return(false);
    }

    function nextJPot() public view returns(uint256) {
      uint256 _cblock = block.number;
      uint256 _jendblock = jendblock;
      uint256 _tmp = (_cblock - _jendblock);
      uint256 _nend = _jendblock + jpotinterval;
      uint256 _c = 0;
      if (jPotclaimed == true) {
        return(0);
      }
      while(_tmp > ((_c + 1) * jpotinterval)) {
        _c += 1;
      }
      _nend += jpotinterval * _c;
      return(_nend);
    }

     
    function addressPicks(address _pAddr, uint256 _pck) public view returns(uint256) {
      return(pAddrxBk[_pAddr][_pck].share);
    }
     
    function addressPaid(address _pAddr, uint256 _pck) public view returns(bool) {
      return(pAddrxBk[_pAddr][_pck].paid);
    }
     
    function pickPot(uint256 _pck) public view returns(uint256) {
      return(pBk[_pck].share);
    }
     
    function pickPlyr(uint256 _pck) public view returns(uint256) {
      return(pBk[_pck].nBet);
    }
     
    function getPot() public view returns(uint256) {
      return(pot);
    }
     
    function getJPot() public view returns(uint256) {
      return(jackpot);
    }
     
    function getWPck() public view returns(uint256) {
      return(wPck);
    }
    function viewJPotclaimed() public view returns(bool) {
      return(jPotclaimed);
    }
    function viewJPotWinner() public view returns(address) {
      return(jPotWinner);
    }
     
    function getEndtime() public view returns(uint256) {
      return(endtime);
    }
     
    function getComm() public view returns(uint256) {
      return(comm);
    }
    function hasStarted() public view returns(bool) {
      return(started);
    }
    function isOver() public view returns(bool) {
      return(ended);
    }
    function pickRatio(uint256 _pck) public view returns(uint256) {
      return(pot / pBk[_pck].share);
    }
    function checkTime() public view returns(bool) {
      uint256 _now = now;
      if (_now < endtime) {
        return(false);
      }
      else {
        return(true);
      }
    }

    function testView(address _pAddr, uint256 _n) public view returns(uint256 sShare, uint256 eShare) {
      return(plyrJBk[_pAddr][_n].sShare, plyrJBk[_pAddr][_n].eShare);
    }

     
    function startYourEngines(uint256 _pcknum, uint256 _endtime) onlyAdministrator() public returns(bool){
      require(!started);
      pcknum = _pcknum;
      endtime = _endtime;
      started = true;
      return(true);
    }
    function adminWinner(uint256 _wPck) onlyAdministrator() public {
      require(_wPck <= pcknum && checkTime() && ended == false);
      ended = true;
      wPck = _wPck;
      shareval = pot / pBk[_wPck].share;
      endblock = block.number;
      uint256 _jendblock = block.number;
      jendblock = _jendblock;
      endblockhash = uint256(keccak256(abi.encodePacked(blockhash(_jendblock - 200))));
    }
    function fuckYouPayMe() onlyAdministrator() public {
      uint256 _commDue = comm - commPaid;
      if (_commDue > 0) {
        admin.transfer(_commDue);
        commPaid += _commDue;
      }
    }
  }