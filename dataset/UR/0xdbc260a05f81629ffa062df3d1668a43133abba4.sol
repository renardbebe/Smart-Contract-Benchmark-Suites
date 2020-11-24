 

pragma solidity ^0.4.21;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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






 
 
contract StrikersPlayerList is Ownable {
   
   
   
   
   
   
   
   
   
   

   
  event PlayerAdded(uint8 indexed id, string name);

   
   
  uint8 public playerCount;

   
   
   
   
  constructor() public {
    addPlayer("Lionel Messi");  
    addPlayer("Cristiano Ronaldo");  
    addPlayer("Neymar");  
    addPlayer("Mohamed Salah");  
    addPlayer("Robert Lewandowski");  
    addPlayer("Kevin De Bruyne");  
    addPlayer("Luka Modrić");  
    addPlayer("Eden Hazard");  
    addPlayer("Sergio Ramos");  
    addPlayer("Toni Kroos");  
    addPlayer("Luis Suárez");  
    addPlayer("Harry Kane");  
    addPlayer("Sergio Agüero");  
    addPlayer("Kylian Mbappé");  
    addPlayer("Gonzalo Higuaín");  
    addPlayer("David de Gea");  
    addPlayer("Antoine Griezmann");  
    addPlayer("N'Golo Kanté");  
    addPlayer("Edinson Cavani");  
    addPlayer("Paul Pogba");  
    addPlayer("Isco");  
    addPlayer("Marcelo");  
    addPlayer("Manuel Neuer");  
    addPlayer("Dries Mertens");  
    addPlayer("James Rodríguez");  
    addPlayer("Paulo Dybala");  
    addPlayer("Christian Eriksen");  
    addPlayer("David Silva");  
    addPlayer("Gabriel Jesus");  
    addPlayer("Thiago");  
    addPlayer("Thibaut Courtois");  
    addPlayer("Philippe Coutinho");  
    addPlayer("Andrés Iniesta");  
    addPlayer("Casemiro");  
    addPlayer("Romelu Lukaku");  
    addPlayer("Gerard Piqué");  
    addPlayer("Mats Hummels");  
    addPlayer("Diego Godín");  
    addPlayer("Mesut Özil");  
    addPlayer("Son Heung-min");  
    addPlayer("Raheem Sterling");  
    addPlayer("Hugo Lloris");  
    addPlayer("Radamel Falcao");  
    addPlayer("Ivan Rakitić");  
    addPlayer("Leroy Sané");  
    addPlayer("Roberto Firmino");  
    addPlayer("Sadio Mané");  
    addPlayer("Thomas Müller");  
    addPlayer("Dele Alli");  
    addPlayer("Keylor Navas");  
    addPlayer("Thiago Silva");  
    addPlayer("Raphaël Varane");  
    addPlayer("Ángel Di María");  
    addPlayer("Jordi Alba");  
    addPlayer("Medhi Benatia");  
    addPlayer("Timo Werner");  
    addPlayer("Gylfi Sigurðsson");  
    addPlayer("Nemanja Matić");  
    addPlayer("Kalidou Koulibaly");  
    addPlayer("Bernardo Silva");  
    addPlayer("Vincent Kompany");  
    addPlayer("João Moutinho");  
    addPlayer("Toby Alderweireld");  
    addPlayer("Emil Forsberg");  
    addPlayer("Mario Mandžukić");  
    addPlayer("Sergej Milinković-Savić");  
    addPlayer("Shinji Kagawa");  
    addPlayer("Granit Xhaka");  
    addPlayer("Andreas Christensen");  
    addPlayer("Piotr Zieliński");  
    addPlayer("Fyodor Smolov");  
    addPlayer("Xherdan Shaqiri");  
    addPlayer("Marcus Rashford");  
    addPlayer("Javier Hernández");  
    addPlayer("Hirving Lozano");  
    addPlayer("Hakim Ziyech");  
    addPlayer("Victor Moses");  
    addPlayer("Jefferson Farfán");  
    addPlayer("Mohamed Elneny");  
    addPlayer("Marcus Berg");  
    addPlayer("Guillermo Ochoa");  
    addPlayer("Igor Akinfeev");  
    addPlayer("Sardar Azmoun");  
    addPlayer("Christian Cueva");  
    addPlayer("Wahbi Khazri");  
    addPlayer("Keisuke Honda");  
    addPlayer("Tim Cahill");  
    addPlayer("John Obi Mikel");  
    addPlayer("Ki Sung-yueng");  
    addPlayer("Bryan Ruiz");  
    addPlayer("Maya Yoshida");  
    addPlayer("Nawaf Al Abed");  
    addPlayer("Lee Chung-yong");  
    addPlayer("Gabriel Gómez");  
    addPlayer("Naïm Sliti");  
    addPlayer("Reza Ghoochannejhad");  
    addPlayer("Mile Jedinak");  
    addPlayer("Mohammad Al-Sahlawi");  
    addPlayer("Aron Gunnarsson");  
    addPlayer("Blas Pérez");  
    addPlayer("Dani Alves");  
    addPlayer("Zlatan Ibrahimović");  
  }

   
   
  function addPlayer(string _name) public onlyOwner {
    require(playerCount < 255, "You've already added the maximum amount of players.");
    emit PlayerAdded(playerCount, _name);
    playerCount++;
  }
}


 
 
contract StrikersChecklist is StrikersPlayerList {
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   

   
   
  enum DeployStep {
    WaitingForStepOne,
    WaitingForStepTwo,
    WaitingForStepThree,
    WaitingForStepFour,
    DoneInitialDeploy
  }

   
   
  enum RarityTier {
    IconicReferral,
    IconicInsert,
    Diamond,
    Gold,
    Silver,
    Bronze
  }

   
   
   
   
   
  uint16[] public tierLimits = [
    0,     
    100,   
    1000,  
    1664,  
    3328,  
    4352   
  ];

   
   
   
   
  struct ChecklistItem {
    uint8 playerId;
    RarityTier tier;
  }

   
  DeployStep public deployStep;

   
  ChecklistItem[] public originalChecklistItems;

   
  ChecklistItem[] public iconicChecklistItems;

   
  ChecklistItem[] public unreleasedChecklistItems;

   
   
   
  function _addOriginalChecklistItem(uint8 _playerId, RarityTier _tier) internal {
    originalChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

   
   
   
  function _addIconicChecklistItem(uint8 _playerId, RarityTier _tier) internal {
    iconicChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

   
   
   
   
  function addUnreleasedChecklistItem(uint8 _playerId, RarityTier _tier) external onlyOwner {
    require(deployStep == DeployStep.DoneInitialDeploy, "Finish deploying the Originals and Iconics sets first.");
    require(unreleasedCount() < 56, "You can't add any more checklist items.");
    require(_playerId < playerCount, "This player doesn't exist in our player list.");
    unreleasedChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

   
  function originalsCount() external view returns (uint256) {
    return originalChecklistItems.length;
  }

   
  function iconicsCount() public view returns (uint256) {
    return iconicChecklistItems.length;
  }

   
  function unreleasedCount() public view returns (uint256) {
    return unreleasedChecklistItems.length;
  }

   
   
   
   
   
   
   
   
   
   
   
   

   
  function deployStepOne() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepOne, "You're not following the steps in order...");

     
    _addOriginalChecklistItem(0, RarityTier.Diamond);  
    _addOriginalChecklistItem(1, RarityTier.Diamond);  
    _addOriginalChecklistItem(2, RarityTier.Diamond);  
    _addOriginalChecklistItem(3, RarityTier.Diamond);  

     
    _addOriginalChecklistItem(4, RarityTier.Gold);  
    _addOriginalChecklistItem(5, RarityTier.Gold);  
    _addOriginalChecklistItem(6, RarityTier.Gold);  
    _addOriginalChecklistItem(7, RarityTier.Gold);  
    _addOriginalChecklistItem(8, RarityTier.Gold);  
    _addOriginalChecklistItem(9, RarityTier.Gold);  
    _addOriginalChecklistItem(10, RarityTier.Gold);  
    _addOriginalChecklistItem(11, RarityTier.Gold);  
    _addOriginalChecklistItem(12, RarityTier.Gold);  
    _addOriginalChecklistItem(13, RarityTier.Gold);  
    _addOriginalChecklistItem(14, RarityTier.Gold);  
    _addOriginalChecklistItem(15, RarityTier.Gold);  
    _addOriginalChecklistItem(16, RarityTier.Gold);  
    _addOriginalChecklistItem(17, RarityTier.Gold);  
    _addOriginalChecklistItem(18, RarityTier.Gold);  
    _addOriginalChecklistItem(19, RarityTier.Gold);  

     
    _addOriginalChecklistItem(20, RarityTier.Silver);  
    _addOriginalChecklistItem(21, RarityTier.Silver);  
    _addOriginalChecklistItem(22, RarityTier.Silver);  
    _addOriginalChecklistItem(23, RarityTier.Silver);  
    _addOriginalChecklistItem(24, RarityTier.Silver);  
    _addOriginalChecklistItem(25, RarityTier.Silver);  
    _addOriginalChecklistItem(26, RarityTier.Silver);  
    _addOriginalChecklistItem(27, RarityTier.Silver);  
    _addOriginalChecklistItem(28, RarityTier.Silver);  
    _addOriginalChecklistItem(29, RarityTier.Silver);  
    _addOriginalChecklistItem(30, RarityTier.Silver);  
    _addOriginalChecklistItem(31, RarityTier.Silver);  
    _addOriginalChecklistItem(32, RarityTier.Silver);  

     
    deployStep = DeployStep.WaitingForStepTwo;
  }

   
  function deployStepTwo() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepTwo, "You're not following the steps in order...");

     
    _addOriginalChecklistItem(33, RarityTier.Silver);  
    _addOriginalChecklistItem(34, RarityTier.Silver);  
    _addOriginalChecklistItem(35, RarityTier.Silver);  
    _addOriginalChecklistItem(36, RarityTier.Silver);  
    _addOriginalChecklistItem(37, RarityTier.Silver);  
    _addOriginalChecklistItem(38, RarityTier.Silver);  
    _addOriginalChecklistItem(39, RarityTier.Silver);  
    _addOriginalChecklistItem(40, RarityTier.Silver);  
    _addOriginalChecklistItem(41, RarityTier.Silver);  
    _addOriginalChecklistItem(42, RarityTier.Silver);  
    _addOriginalChecklistItem(43, RarityTier.Silver);  
    _addOriginalChecklistItem(44, RarityTier.Silver);  
    _addOriginalChecklistItem(45, RarityTier.Silver);  
    _addOriginalChecklistItem(46, RarityTier.Silver);  
    _addOriginalChecklistItem(47, RarityTier.Silver);  
    _addOriginalChecklistItem(48, RarityTier.Silver);  
    _addOriginalChecklistItem(49, RarityTier.Silver);  

     
    _addOriginalChecklistItem(50, RarityTier.Bronze);  
    _addOriginalChecklistItem(51, RarityTier.Bronze);  
    _addOriginalChecklistItem(52, RarityTier.Bronze);  
    _addOriginalChecklistItem(53, RarityTier.Bronze);  
    _addOriginalChecklistItem(54, RarityTier.Bronze);  
    _addOriginalChecklistItem(55, RarityTier.Bronze);  
    _addOriginalChecklistItem(56, RarityTier.Bronze);  
    _addOriginalChecklistItem(57, RarityTier.Bronze);  
    _addOriginalChecklistItem(58, RarityTier.Bronze);  
    _addOriginalChecklistItem(59, RarityTier.Bronze);  
    _addOriginalChecklistItem(60, RarityTier.Bronze);  
    _addOriginalChecklistItem(61, RarityTier.Bronze);  
    _addOriginalChecklistItem(62, RarityTier.Bronze);  
    _addOriginalChecklistItem(63, RarityTier.Bronze);  
    _addOriginalChecklistItem(64, RarityTier.Bronze);  
    _addOriginalChecklistItem(65, RarityTier.Bronze);  

     
    deployStep = DeployStep.WaitingForStepThree;
  }

   
  function deployStepThree() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepThree, "You're not following the steps in order...");

     
    _addOriginalChecklistItem(66, RarityTier.Bronze);  
    _addOriginalChecklistItem(67, RarityTier.Bronze);  
    _addOriginalChecklistItem(68, RarityTier.Bronze);  
    _addOriginalChecklistItem(69, RarityTier.Bronze);  
    _addOriginalChecklistItem(70, RarityTier.Bronze);  
    _addOriginalChecklistItem(71, RarityTier.Bronze);  
    _addOriginalChecklistItem(72, RarityTier.Bronze);  
    _addOriginalChecklistItem(73, RarityTier.Bronze);  
    _addOriginalChecklistItem(74, RarityTier.Bronze);  
    _addOriginalChecklistItem(75, RarityTier.Bronze);  
    _addOriginalChecklistItem(76, RarityTier.Bronze);  
    _addOriginalChecklistItem(77, RarityTier.Bronze);  
    _addOriginalChecklistItem(78, RarityTier.Bronze);  
    _addOriginalChecklistItem(79, RarityTier.Bronze);  
    _addOriginalChecklistItem(80, RarityTier.Bronze);  
    _addOriginalChecklistItem(81, RarityTier.Bronze);  
    _addOriginalChecklistItem(82, RarityTier.Bronze);  
    _addOriginalChecklistItem(83, RarityTier.Bronze);  
    _addOriginalChecklistItem(84, RarityTier.Bronze);  
    _addOriginalChecklistItem(85, RarityTier.Bronze);  
    _addOriginalChecklistItem(86, RarityTier.Bronze);  
    _addOriginalChecklistItem(87, RarityTier.Bronze);  
    _addOriginalChecklistItem(88, RarityTier.Bronze);  
    _addOriginalChecklistItem(89, RarityTier.Bronze);  
    _addOriginalChecklistItem(90, RarityTier.Bronze);  
    _addOriginalChecklistItem(91, RarityTier.Bronze);  
    _addOriginalChecklistItem(92, RarityTier.Bronze);  
    _addOriginalChecklistItem(93, RarityTier.Bronze);  
    _addOriginalChecklistItem(94, RarityTier.Bronze);  
    _addOriginalChecklistItem(95, RarityTier.Bronze);  
    _addOriginalChecklistItem(96, RarityTier.Bronze);  
    _addOriginalChecklistItem(97, RarityTier.Bronze);  
    _addOriginalChecklistItem(98, RarityTier.Bronze);  
    _addOriginalChecklistItem(99, RarityTier.Bronze);  

     
    deployStep = DeployStep.WaitingForStepFour;
  }

   
  function deployStepFour() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepFour, "You're not following the steps in order...");

     
    _addIconicChecklistItem(0, RarityTier.IconicInsert);  
    _addIconicChecklistItem(1, RarityTier.IconicInsert);  
    _addIconicChecklistItem(2, RarityTier.IconicInsert);  
    _addIconicChecklistItem(3, RarityTier.IconicInsert);  
    _addIconicChecklistItem(4, RarityTier.IconicInsert);  
    _addIconicChecklistItem(5, RarityTier.IconicInsert);  
    _addIconicChecklistItem(6, RarityTier.IconicInsert);  
    _addIconicChecklistItem(7, RarityTier.IconicInsert);  
    _addIconicChecklistItem(8, RarityTier.IconicInsert);  
    _addIconicChecklistItem(9, RarityTier.IconicInsert);  
    _addIconicChecklistItem(10, RarityTier.IconicInsert);  
    _addIconicChecklistItem(11, RarityTier.IconicInsert);  
    _addIconicChecklistItem(12, RarityTier.IconicInsert);  
    _addIconicChecklistItem(15, RarityTier.IconicInsert);  
    _addIconicChecklistItem(16, RarityTier.IconicInsert);  
    _addIconicChecklistItem(17, RarityTier.IconicReferral);  
    _addIconicChecklistItem(18, RarityTier.IconicReferral);  
    _addIconicChecklistItem(19, RarityTier.IconicInsert);  
    _addIconicChecklistItem(21, RarityTier.IconicInsert);  
    _addIconicChecklistItem(24, RarityTier.IconicInsert);  
    _addIconicChecklistItem(26, RarityTier.IconicInsert);  
    _addIconicChecklistItem(29, RarityTier.IconicReferral);  
    _addIconicChecklistItem(36, RarityTier.IconicReferral);  
    _addIconicChecklistItem(38, RarityTier.IconicReferral);  
    _addIconicChecklistItem(39, RarityTier.IconicInsert);  
    _addIconicChecklistItem(46, RarityTier.IconicInsert);  
    _addIconicChecklistItem(48, RarityTier.IconicInsert);  
    _addIconicChecklistItem(49, RarityTier.IconicReferral);  
    _addIconicChecklistItem(73, RarityTier.IconicInsert);  
    _addIconicChecklistItem(85, RarityTier.IconicInsert);  
    _addIconicChecklistItem(100, RarityTier.IconicReferral);  
    _addIconicChecklistItem(101, RarityTier.IconicReferral);  

     
    deployStep = DeployStep.DoneInitialDeploy;
  }

   
   
   
  function limitForChecklistId(uint8 _checklistId) external view returns (uint16) {
    RarityTier rarityTier;
    uint8 index;
    if (_checklistId < 100) {  
      rarityTier = originalChecklistItems[_checklistId].tier;
    } else if (_checklistId < 200) {  
      index = _checklistId - 100;
      require(index < iconicsCount(), "This Iconics checklist item doesn't exist.");
      rarityTier = iconicChecklistItems[index].tier;
    } else {  
      index = _checklistId - 200;
      require(index < unreleasedCount(), "This Unreleased checklist item doesn't exist.");
      rarityTier = unreleasedChecklistItems[index].tier;
    }
    return tierLimits[uint8(rarityTier)];
  }
}