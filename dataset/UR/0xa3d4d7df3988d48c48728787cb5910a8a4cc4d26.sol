 

contract Etheropt {

  struct Option {
    int strike;
  }
  struct Position {
    mapping(uint => int) positions;
    int cash;
    bool expired;
    bool hasPosition;
  }
  struct OptionChain {
    uint expiration;
    string underlying;
    uint margin;
    uint realityID;
    bytes32 factHash;
    address ethAddr;
    mapping(uint => Option) options;
    uint numOptions;
    bool expired;
    mapping(address => Position) positions;
    uint numPositions;
    uint numPositionsExpired;
  }
  mapping(uint => OptionChain) optionChains;
  uint numOptionChains;
  struct Account {
    address user;
    int capital;
  }
  mapping(bytes32 => int) orderFills;  
  struct MarketMaker {
    address user;
    string server;
  }
  mapping(uint => MarketMaker) marketMakers;  
  uint public numMarketMakers = 0;
  mapping(address => uint) marketMakerIDs;
  mapping(uint => Account) accounts;
  uint public numAccounts;
  mapping(address => uint) accountIDs;  

  function Market() {
  }

  function getAccountID(address user) constant returns(uint) {
    return accountIDs[user];
  }

  function getAccount(uint accountID) constant returns(address) {
    return accounts[accountID].user;
  }

  function addFunds() {
    if (accountIDs[msg.sender]>0) {
      accounts[accountIDs[msg.sender]].capital += int(msg.value);
    } else {
      uint accountID = ++numAccounts;
      accounts[accountID].user = msg.sender;
      accounts[accountID].capital += int(msg.value);
      accountIDs[msg.sender] = accountID;
    }
  }

  function withdrawFunds(uint amount) {
    if (accountIDs[msg.sender]>0) {
      if (int(amount)<=getFunds(msg.sender, true) && int(amount)>0) {
        accounts[accountIDs[msg.sender]].capital -= int(amount);
        msg.sender.send(amount);
      }
    }
  }

  function getFunds(address user, bool onlyAvailable) constant returns(int) {
    if (accountIDs[user]>0) {
      if (onlyAvailable == false) {
        return accounts[accountIDs[user]].capital;
      } else {
        return accounts[accountIDs[user]].capital + getMaxLossAfterTrade(user, 0, 0, 0, 0);
      }
    } else {
      return 0;
    }
  }

  function getFundsAndAvailable(address user) constant returns(int, int) {
    return (getFunds(user, false), getFunds(user, true));
  }

  function marketMaker(string server) {
    if (msg.value>0) throw;
    if (marketMakerIDs[msg.sender]>0) {
      marketMakers[marketMakerIDs[msg.sender]].server = server;
    } else {
      int funds = getFunds(marketMakers[i].user, false);
      uint marketMakerID = 0;
      if (numMarketMakers<6) {
        marketMakerID = ++numMarketMakers;
      } else {
        for (uint i=2; i<=numMarketMakers; i++) {
          if (getFunds(marketMakers[i].user, false)<=funds && (marketMakerID==0 || getFunds(marketMakers[i].user, false)<getFunds(marketMakers[marketMakerID].user, false))) {
            marketMakerID = i;
          }
        }
      }
      if (marketMakerID>0) {
        marketMakerIDs[marketMakers[marketMakerID].user] = 0;
        marketMakers[marketMakerID].user = msg.sender;
        marketMakers[marketMakerID].server = server;
        marketMakerIDs[msg.sender] = marketMakerID;
      } else {
        throw;
      }
    }
  }

  function getMarketMakers() constant returns(string, string, string, string, string, string) {
    string[] memory servers = new string[](6);
    for (uint i=1; i<=numMarketMakers; i++) {
      servers[i-1] = marketMakers[i].server;
    }
    return (servers[0], servers[1], servers[2], servers[3], servers[4], servers[5]);
  }

  function getMarketMakerFunds() constant returns(int, int, int, int, int, int) {
    int[] memory funds = new int[](6);
    for (uint i=1; i<=numMarketMakers; i++) {
      funds[i-1] = getFunds(marketMakers[i].user, false);
    }
    return (funds[0], funds[1], funds[2], funds[3], funds[4], funds[5]);
  }

  function getOptionChain(uint optionChainID) constant returns (uint, string, uint, uint, bytes32, address) {
    return (optionChains[optionChainID].expiration, optionChains[optionChainID].underlying, optionChains[optionChainID].margin, optionChains[optionChainID].realityID, optionChains[optionChainID].factHash, optionChains[optionChainID].ethAddr);
  }

  function getMarket(address user) constant returns(uint[], int[], int[], int[]) {
    uint[] memory optionIDs = new uint[](60);
    int[] memory strikes = new int[](60);
    int[] memory positions = new int[](60);
    int[] memory cashes = new int[](60);
    uint z = 0;
    for (int optionChainID=int(numOptionChains)-1; optionChainID>=0 && z<60; optionChainID--) {
      if (optionChains[uint(optionChainID)].expired == false) {
        for (uint optionID=0; optionID<optionChains[uint(optionChainID)].numOptions; optionID++) {
          optionIDs[z] = uint(optionChainID)*1000 + optionID;
          strikes[z] = optionChains[uint(optionChainID)].options[optionID].strike;
          positions[z] = optionChains[uint(optionChainID)].positions[user].positions[optionID];
          cashes[z] = optionChains[uint(optionChainID)].positions[user].cash;
          z++;
        }
      }
    }
    return (optionIDs, strikes, positions, cashes);
  }

  function expire(uint accountID, uint optionChainID, uint8 v, bytes32 r, bytes32 s, bytes32 value) {
    if (optionChains[optionChainID].expired == false) {
      if (ecrecover(sha3(optionChains[optionChainID].factHash, value), v, r, s) == optionChains[optionChainID].ethAddr) {
        uint lastAccount = numAccounts;
        if (accountID==0) {
          accountID = 1;
        } else {
          lastAccount = accountID;
        }
        for (accountID=accountID; accountID<=lastAccount; accountID++) {
          if (optionChains[optionChainID].positions[accounts[accountID].user].expired == false) {
            int result = optionChains[optionChainID].positions[accounts[accountID].user].cash / 1000000000000000000;
            for (uint optionID=0; optionID<optionChains[optionChainID].numOptions; optionID++) {
              int moneyness = getMoneyness(optionChains[optionChainID].options[optionID].strike, uint(value), optionChains[optionChainID].margin);
              result += moneyness * optionChains[optionChainID].positions[accounts[accountID].user].positions[optionID] / 1000000000000000000;
            }
            accounts[accountID].capital = accounts[accountID].capital + result;
            optionChains[optionChainID].positions[accounts[accountID].user].expired = true;
            optionChains[optionChainID].numPositionsExpired++;
          }
        }
        if (optionChains[optionChainID].numPositionsExpired == optionChains[optionChainID].numPositions) {
          optionChains[optionChainID].expired = true;
        }
      }
    }
  }

  function getMoneyness(int strike, uint settlement, uint margin) constant returns(int) {
    if (strike>=0) {  
      if (settlement>uint(strike)) {
        if (settlement-uint(strike)<margin) {
          return int(settlement-uint(strike));
        } else {
          return int(margin);
        }
      } else {
        return 0;
      }
    } else {  
      if (settlement<uint(-strike)) {
        if (uint(-strike)-settlement<margin) {
          return int(uint(-strike)-settlement);
        } else {
          return int(margin);
        }
      } else {
        return 0;
      }
    }
  }

  function addOptionChain(uint expiration, string underlying, uint margin, uint realityID, bytes32 factHash, address ethAddr, int[] strikes) {
    uint optionChainID = 6;
    if (numOptionChains<6) {
      optionChainID = numOptionChains++;
    } else {
      for (uint i=0; i < numOptionChains && optionChainID>=6; i++) {
        if (optionChains[i].expired==true || optionChains[i].numPositions==0 || optionChains[i].numOptions==0) {
          optionChainID = i;
        }
      }
    }
    if (optionChainID<6) {
      delete optionChains[optionChainID];
      optionChains[optionChainID].expiration = expiration;
      optionChains[optionChainID].underlying = underlying;
      optionChains[optionChainID].margin = margin;
      optionChains[optionChainID].realityID = realityID;
      optionChains[optionChainID].factHash = factHash;
      optionChains[optionChainID].ethAddr = ethAddr;
      for (i=0; i < strikes.length; i++) {
        if (optionChains[optionChainID].numOptions<10) {
          uint optionID = optionChains[optionChainID].numOptions++;
          Option option = optionChains[optionChainID].options[i];
          option.strike = strikes[i];
          optionChains[optionChainID].options[i] = option;
        }
      }
    }
  }

  function orderMatchTest(uint optionChainID, uint optionID, uint price, int size, uint orderID, uint blockExpires, address addr, address sender, int matchSize) constant returns(bool) {
    if (block.number<=blockExpires && ((size>0 && matchSize<0 && orderFills[sha3(optionChainID, optionID, price, size, orderID, blockExpires)]-matchSize<=size) || (size<0 && matchSize>0 && orderFills[sha3(optionChainID, optionID, price, size, orderID, blockExpires)]-matchSize>=size)) && getFunds(addr, false)+getMaxLossAfterTrade(addr, optionChainID, optionID, -matchSize, matchSize * int(price))>0 && getFunds(sender, false)+getMaxLossAfterTrade(sender, optionChainID, optionID, matchSize, -matchSize * int(price))>0) {
      return true;
    }
    return false;
  }

  function orderMatch(uint optionChainID, uint optionID, uint price, int size, uint orderID, uint blockExpires, address addr, uint8 v, bytes32 r, bytes32 s, int matchSize) {
    bytes32 hash = sha256(optionChainID, optionID, price, size, orderID, blockExpires);
    if (ecrecover(hash, v, r, s) == addr && block.number<=blockExpires && ((size>0 && matchSize<0 && orderFills[hash]-matchSize<=size) || (size<0 && matchSize>0 && orderFills[hash]-matchSize>=size)) && getFunds(addr, false)+getMaxLossAfterTrade(addr, optionChainID, optionID, -matchSize, matchSize * int(price))>0 && getFunds(msg.sender, false)+getMaxLossAfterTrade(msg.sender, optionChainID, optionID, matchSize, -matchSize * int(price))>0) {
      if (optionChains[optionChainID].positions[msg.sender].hasPosition == false) {
        optionChains[optionChainID].positions[msg.sender].hasPosition = true;
        optionChains[optionChainID].numPositions++;
      }
      if (optionChains[optionChainID].positions[addr].hasPosition == false) {
        optionChains[optionChainID].positions[addr].hasPosition = true;
        optionChains[optionChainID].numPositions++;
      }
      optionChains[optionChainID].positions[msg.sender].positions[optionID] += matchSize;
      optionChains[optionChainID].positions[msg.sender].cash -= matchSize * int(price);
      optionChains[optionChainID].positions[addr].positions[optionID] -= matchSize;
      optionChains[optionChainID].positions[addr].cash += matchSize * int(price);
      orderFills[hash] -= matchSize;
    }
  }

  function getMaxLossAfterTrade(address user, uint optionChainID, uint optionID, int positionChange, int cashChange) constant returns(int) {
    int totalMaxLoss = 0;
    for (uint i=0; i<numOptionChains; i++) {
      if (optionChains[i].positions[user].expired == false && optionChains[i].numOptions>0) {
        bool maxLossInitialized = false;
        int maxLoss = 0;
        for (uint s=0; s<optionChains[i].numOptions; s++) {
          int pnl = optionChains[i].positions[user].cash / 1000000000000000000;
          if (i==optionChainID) {
            pnl += cashChange / 1000000000000000000;
          }
          uint settlement = 0;
          if (optionChains[i].options[s].strike<0) {
            settlement = uint(-optionChains[i].options[s].strike);
          } else {
            settlement = uint(optionChains[i].options[s].strike);
          }
          pnl += moneySumAtSettlement(user, optionChainID, optionID, positionChange, i, settlement);
          if (pnl<maxLoss || maxLossInitialized==false) {
            maxLossInitialized = true;
            maxLoss = pnl;
          }
          pnl = optionChains[i].positions[user].cash / 1000000000000000000;
          if (i==optionChainID) {
            pnl += cashChange / 1000000000000000000;
          }
          settlement = 0;
          if (optionChains[i].options[s].strike<0) {
            if (uint(-optionChains[i].options[s].strike)>optionChains[i].margin) {
              settlement = uint(-optionChains[i].options[s].strike)-optionChains[i].margin;
            } else {
              settlement = 0;
            }
          } else {
            settlement = uint(optionChains[i].options[s].strike)+optionChains[i].margin;
          }
          pnl += moneySumAtSettlement(user, optionChainID, optionID, positionChange, i, settlement);
          if (pnl<maxLoss) {
            maxLoss = pnl;
          }
        }
        totalMaxLoss += maxLoss;
      }
    }
    return totalMaxLoss;
  }

  function moneySumAtSettlement(address user, uint optionChainID, uint optionID, int positionChange, uint i, uint settlement) internal returns(int) {
    int pnl = 0;
    for (uint j=0; j<optionChains[i].numOptions; j++) {
      pnl += optionChains[i].positions[user].positions[j] * getMoneyness(optionChains[i].options[j].strike, settlement, optionChains[i].margin) / 1000000000000000000;
      if (i==optionChainID && j==optionID) {
        pnl += positionChange * getMoneyness(optionChains[i].options[j].strike, settlement, optionChains[i].margin) / 1000000000000000000;
      }
    }
    return pnl;
  }

  function min(uint a, uint b) constant returns(uint) {
    if (a<b) {
      return a;
    } else {
      return b;
    }
  }
}