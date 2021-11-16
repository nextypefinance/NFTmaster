pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/INFTcustom.sol";

contract BlindBox is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    address[] public adminList;

    address[] public NFTList;
    uint256[] public SupplyList;
    
    uint256 public payPrice;
    address public payToken;

    bool public boxStatus;
    address public platformAddress;

    event Burn(uint256 tokenId, uint256 orderId);
    event BlindPurchase(address NFTaddress, uint256 tokenId);


    constructor() public {
        adminList.push(msg.sender);
        boxStatus = false;

        platformAddress = msg.sender;
    }
  
    function blindPurchase() public nonReentrant returns(address, uint256){
        uint256 remaining = getRemainder();
        require(remaining > 0, "supply is 0");
        require(boxStatus == true, "box is pause");

        IERC20(payToken).transferFrom(msg.sender, platformAddress, payPrice);

        uint256 randomness_ = psuedoRandomness();
        randomness_ = randomness_.mod(remaining);
 
        address resultAddress;

        for ( uint256 ind = 0; ind < SupplyList.length; ind++){
            if(randomness_ <= SupplyList[ind] && SupplyList[ind] > 0){
                resultAddress = NFTList[ind];
                SupplyList[ind] = SupplyList[ind].sub(1);
                break;
            }else{
                randomness_ = randomness_.sub(SupplyList[ind]);
            }
        }

        uint256 tokenId = INFTcustom(resultAddress).mintItem(msg.sender);
        
        emit BlindPurchase(resultAddress, tokenId);
        
        return (resultAddress, tokenId);
    }

    function getRemainder() public view returns(uint256){
        uint256 _tmpSupply = 0;
        for ( uint256 nIndex = 0; nIndex < SupplyList.length; nIndex++){
            _tmpSupply = _tmpSupply.add(SupplyList[nIndex]);
        }
        return _tmpSupply;
    }

    function setBoxSupply(address[] memory _addressList, uint256[] memory _numberList) public nonReentrant{
        require(onlyAdmin(msg.sender), "Only administrators can operate");
        require(_addressList.length > 0, "_addressList is empty");
        require(_addressList.length == _numberList.length, "Inconsistent array length");

        for ( uint256 nIndex = 0; nIndex < _addressList.length; nIndex++){
            require(_addressList[nIndex] != address(0), "NFT address is empty");
        }
        NFTList = _addressList;
        SupplyList = _numberList;
    }

    function setStatus(bool _status) public nonReentrant{
        require(onlyAdmin(msg.sender), "Only administrators can operate");
         boxStatus = _status;
    }

    function setPrice(address _token, uint256 _price) public nonReentrant{
        require(onlyAdmin(msg.sender), "Only administrators can operate");
        require(_token != address(0), "_token is empty");
        require(_price > 0, "_price is empty");
        payToken = _token;
        payPrice = _price;
    }

    function setPlatformAddress(address _token) public nonReentrant{
        require(onlyAdmin(msg.sender), "Only administrators can operate");
        require(_token != address(0), "_token is empty");

        platformAddress = _token;
    }

    function setAdminList(address[] memory _list) public onlyOwner nonReentrant{
        require(_list.length > 0, "_list is empty");
        
        for ( uint256 nIndex = 0; nIndex < _list.length; nIndex++){
            require(_list[nIndex] != address(0), "admin is empty");
        }
        adminList = _list;
    }

    function onlyAdmin(address token) internal view returns (bool) {
        for ( uint256 nIndex = 0; nIndex < adminList.length; nIndex++){
            if (adminList[nIndex] == token) {
                return true;
            }
        }
        return false;
    }


    function psuedoRandomness() public view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
            block.number
        )));
    }
}



