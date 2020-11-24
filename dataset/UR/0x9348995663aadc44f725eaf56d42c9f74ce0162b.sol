 

pragma solidity >=0.5.8;
 

contract manekio {

   
  event playerBet (
    uint256 BetID,
    address playerAddress,
    uint256 pick,
    uint256 eth
    );
  event playerPaid (
    uint256 BetID,
    address playerAddress,
    uint256 pick,
    uint256 eth
    );
  event jackpotClaim (
    uint256 BetID,
    address playerAddress,
    uint256 eth
    );
  event adminStart (
    uint256 betID,
    uint256 pcknum,
    uint256 endtime,
    uint256 bEndtime
    );
  event adminEndWin (
    uint256 betID,
    uint256 wPck
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
      uint256 eth;
      bool paid;
    }
    struct pickBook {
      uint256 share;  
      uint256 nBet;  
    }
    struct betDataBook {
       
      string pckname;
      uint256 pcknum;
      uint256 endtime;
      uint256 bEndtime;

       
      uint256 tShare;
      uint256 comm;
      uint256 commPaid;
      uint256 jackpot;

       
      bool started;
      bool ended;
      bool refund;

       
      uint256 wPck;
      uint256 shareval;
      uint256 jendblock;
      uint256 endblockhash;
      address jPotWinner;
      bool jPotclaimed;
    }

     
    mapping(uint256 => mapping(address => mapping(uint256 => playerJBook))) internal plyrJBk;  
    mapping(uint256 => mapping(address => mapping(uint256 => playerBook))) internal pAddrxBk;  
    mapping(uint256 => mapping(uint256 => pickBook)) internal pBk;  
    mapping(uint256 => betDataBook) internal bDB;  

    uint256 internal commrate = 25;
    uint256 internal jpotrate = 25;
    uint256 internal jpotinterval = 6000;

    address payable internal admin = 0xe7Cef4D90BdA19A6e2A20F12A1A6C394230d2924;
    uint256 internal donations = 0;
    uint256 internal donationsPaid = 0;


     
     
    function() external payable {
      require(msg.value > 0);
      donations += msg.value;
    }
     
     
    function playerPick(uint256 _bID, uint256 _pck) public payable {
      address _pAddr = msg.sender;
      uint256 _eth = msg.value;
      require(_eth > 0);
       
      if (_eth >= 1e16 && !checkTime(_bID) && !bDB[_bID].ended && _pck <= bDB[_bID].pcknum && bDB[_bID].started && !bDB[_bID].refund) {
         
        uint256 _commEth = _eth / commrate;
        uint256 _jpEth = _eth / jpotrate;
        uint256 _potEth = _eth - _commEth - _jpEth;
         
        uint256 _share = _potEth / 1e13;
         
        bDB[_bID].comm += _commEth;
        bDB[_bID].jackpot += _jpEth + (_potEth % 1e13);
        pBk[_bID][_pck].nBet += 1;
        pBk[_bID][_pck].share += _share;
         
        for(uint256 i = 0; true; i++) {
          if(plyrJBk[_bID][_pAddr][i].eShare == 0){
            plyrJBk[_bID][_pAddr][i].sShare = bDB[_bID].tShare;
            plyrJBk[_bID][_pAddr][i].eShare = bDB[_bID].tShare + _share - 1;
            break;
          }
        }
         
        bDB[_bID].tShare += _share;
         
        pAddrxBk[_bID][_pAddr][_pck].share += _share;
        pAddrxBk[_bID][_pAddr][_pck].eth += _eth;
         
        emit playerBet(_bID, _pAddr, _pck, _potEth);
      }
      else {
        donations += _eth;
      }
    }
     
    function claimJackpot(uint256 _bID) public {
      address payable _pAddr = msg.sender;
      uint256 _jackpot = bDB[_bID].jackpot;
      require(bDB[_bID].ended == true && checkJPotWinner(_bID, _pAddr) && !bDB[_bID].jPotclaimed && bDB[_bID].refund == false);
      bDB[_bID].jPotclaimed = true;
      bDB[_bID].jPotWinner = _pAddr;
      _pAddr.transfer(_jackpot);
      emit jackpotClaim(_bID, _pAddr, _jackpot);
    }
     
    function payMeBitch(uint256 _bID, uint256 _pck) public {
      address payable _pAddr = msg.sender;
      require(pAddrxBk[_bID][_pAddr][_pck].paid == false && pAddrxBk[_bID][_pAddr][_pck].share > 0 && bDB[_bID].wPck == _pck && bDB[_bID].refund == false && bDB[_bID].ended == true);
      uint256 _eth = pAddrxBk[_bID][_pAddr][_pck].share * bDB[_bID].shareval;
      pAddrxBk[_bID][_pAddr][_pck].paid = true;
      _pAddr.transfer(_eth);
      emit playerPaid(_bID, _pAddr, _pck, _eth);
    }
     
    function giveMeRefund(uint256 _bID, uint256 _pck) public {
      address payable _pAddr = msg.sender;
      require(bDB[_bID].refund == true);
      require(pAddrxBk[_bID][_pAddr][_pck].paid == false && pAddrxBk[_bID][_pAddr][_pck].eth > 0);
      pAddrxBk[_bID][_pAddr][_pck].paid = true;
      _pAddr.transfer(pAddrxBk[_bID][_pAddr][_pck].eth);
    }

     
     
    function checkJPotWinner(uint256 _bID, address payable _pAddr) public view returns(bool){
      uint256 _endblockhash = bDB[_bID].endblockhash;
      uint256 _tShare = bDB[_bID].tShare;
      uint256 _nend = nextJPot(_bID);
      uint256 _wnum;
      require(plyrJBk[_bID][_pAddr][0].eShare != 0);
      if (bDB[_bID].jPotclaimed == true) {
        return(false);
      }
       
      _endblockhash = uint256(keccak256(abi.encodePacked(_endblockhash + _nend)));
      _wnum = (_endblockhash % _tShare);
      for(uint256 i = 0; true; i++) {
        if(plyrJBk[_bID][_pAddr][i].eShare == 0){
          break;
        }
        else {
          if (plyrJBk[_bID][_pAddr][i].sShare <= _wnum && plyrJBk[_bID][_pAddr][i].eShare >= _wnum ){
            return(true);
          }
        }
      }
      return(false);
    }
     
    function nextJPot(uint256 _bID) public view returns(uint256) {
      uint256 _cblock = block.number;
      uint256 _jendblock = bDB[_bID].jendblock;
      uint256 _tmp = (_cblock - _jendblock);
      uint256 _nend = _jendblock + jpotinterval;
      uint256 _c = 0;
      if (bDB[_bID].jPotclaimed == true) {
        return(0);
      }
      while(_tmp > ((_c + 1) * jpotinterval)) {
        _c += 1;
      }
      _nend += jpotinterval * _c;
      return(_nend);
    }
     
     
    function addressPicks(uint256 _bID, address _pAddr, uint256 _pck) public view returns(uint256) {return(pAddrxBk[_bID][_pAddr][_pck].share);}
     
    function addressPaid(uint256 _bID, address _pAddr, uint256 _pck) public view returns(bool) {return(pAddrxBk[_bID][_pAddr][_pck].paid);}
     
    function pickPot(uint256 _bID, uint256 _pck) public view returns(uint256) {return(pBk[_bID][_pck].share);}
     
    function pickPlyr(uint256 _bID, uint256 _pck) public view returns(uint256) {return(pBk[_bID][_pck].nBet);}
     
    function pickRatio(uint256 _bID, uint256 _pck) public view returns(uint256) {return(bDB[_bID].tShare * 1e13 / pBk[_bID][_pck].share);}
    function getPot(uint256 _bID) public view returns(uint256) {return(bDB[_bID].tShare * 1e13);}
    function getJPot(uint256 _bID) public view returns(uint256) {return(bDB[_bID].jackpot);}
    function getWPck(uint256 _bID) public view returns(uint256) {return(bDB[_bID].wPck);}
    function viewJPotclaimed(uint256 _bID) public view returns(bool) {return(bDB[_bID].jPotclaimed);}
    function viewJPotWinner(uint256 _bID) public view returns(address) {return(bDB[_bID].jPotWinner);}

     
    function viewPck(uint256 _bID) public view returns(string memory name, uint256 num) {return(bDB[_bID].pckname, bDB[_bID].pcknum);}
    function getEndtime(uint256 _bID) public view returns(uint256) {return(bDB[_bID].endtime);}
    function getBEndtime(uint256 _bID) public view returns(uint256) {return(bDB[_bID].bEndtime);}

     
    function hasStarted(uint256 _bID) public view returns(bool) {return(bDB[_bID].started);}
    function isOver(uint256 _bID) public view returns(bool) {return(bDB[_bID].ended);}
    function isRefund(uint256 _bID) public view returns(bool){return(bDB[_bID].refund);}

    function checkTime(uint256 _bID) public view returns(bool) {
      uint256 _now = now;
      if (_now < bDB[_bID].endtime) {
        return(false);
      }
      else {
        return(true);
      }
    }
     
    function getComm(uint256 _bID) public view returns(uint256 comm, uint256 commPaid) {return(bDB[_bID].comm, bDB[_bID].commPaid);}
    function getDon() public view returns(uint256 don, uint256 donPaid) {return(donations, donationsPaid);}

     
    function adminStartBet(uint256 _bID, string memory _pckname, uint256 _pcknum, uint256 _endtime, uint256 _bEndtime) onlyAdministrator() public {
      require(!bDB[_bID].started);
      bDB[_bID].pckname = _pckname;
      bDB[_bID].pcknum = _pcknum;
      bDB[_bID].endtime = _endtime;
      bDB[_bID].bEndtime = _bEndtime;
      bDB[_bID].started = true;
      emit adminStart(_bID, _pcknum, _endtime, _bEndtime);
    }
    function adminWinner(uint256 _bID, uint256 _wPck) onlyAdministrator() public {
      require(_wPck <= bDB[_bID].pcknum && checkTime(_bID) && bDB[_bID].ended == false && bDB[_bID].refund == false);
      bDB[_bID].ended = true;
      bDB[_bID].wPck = _wPck;
      uint256 _shareval = (1e13 * bDB[_bID].tShare) / pBk[_bID][_wPck].share;
      bDB[_bID].shareval = _shareval;
      uint256 _rem = (1e13 * bDB[_bID].tShare ) % pBk[_bID][_wPck].share;
      if (_rem > 0) {
        donations += _rem;
      }
      uint256 _jendblock = block.number;
      bDB[_bID].jendblock = _jendblock;
       
      bDB[_bID].endblockhash = uint256(keccak256(abi.encodePacked(blockhash(_jendblock - 200))));
      emit adminEndWin(_bID, _wPck);
    }
    function fuckYouPayMe(uint256 _bID) onlyAdministrator() public {
      require(checkTime(_bID) == true && bDB[_bID].refund == false);
      uint256 _commDue = bDB[_bID].comm - bDB[_bID].commPaid;
      if (_commDue > 0) {
        bDB[_bID].commPaid += _commDue;
        admin.transfer(_commDue);
      }
    }
    function adminRefund(uint256 _bID) onlyAdministrator() public {
      require(bDB[_bID].ended != true && bDB[_bID].refund != true);
      bDB[_bID].refund = true;
    }
    function adminRake() onlyAdministrator() public {
      uint256 _donDue = donations - donationsPaid;
      if (_donDue > 0) {
        donationsPaid += _donDue;
        admin.transfer(_donDue);
      }
    }
  }