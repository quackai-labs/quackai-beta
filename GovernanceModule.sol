
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10 <0.8.19;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract QuackAiVote is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    struct sProposalProperty {
        bool start;
        uint256 startTime;
        uint256 endTime;
        string url;
        string title;
        address proposer;
        uint256 proposalType;
        uint256 minQuorum;
        mapping(address => bool) bAddrVote;
        mapping(address => uint256) addrWeight;
        mapping(address => uint256) addrWeightType;
        mapping(address => uint256) addrVoteTime;
        uint256 totalVoteFor;
        uint256 totalVoteAgainst;
        uint256 totalAbstain;
        uint256 sumCount;
        address[] voteAddrArr;
    }
    mapping(uint256 => sProposalProperty) private _proposals;
    uint256 public nowId=0;
    
    mapping (address => bool) private _Is_WhiteAddrArr;
    address[] private _WhiteAddrArr;

    constructor() {
    }


    /* ========== VIEWS ========== */
    function getNowTIme() external view returns(uint256){
        return block.timestamp;
    }
    function totalProposal() external view returns (uint256) {
        return nowId;
    }
    function getUrl(uint256 id) public view returns (string memory){
        return _proposals[id].url;
    }
    function getTitle(uint256 id) public view returns (string memory){
        return _proposals[id].title;
    }
    function getVoteAddressNum(uint256 id) external view returns (uint256) {
        return _proposals[id].sumCount;
    }

    function getProposalInfoArr1(uint256 fromId,uint256 toId) public view returns (
        uint256[] memory idArr,
        string[] memory urlArr,//url
        string[] memory titleArr,//title
        uint256[] memory startTimeArr,
        uint256[] memory endTimeArr,
        address[] memory proposerArr,
        uint256[] memory proposalTypeArr
    ){
        idArr = new uint256[](toId-fromId+1);
        urlArr = new string[](toId-fromId+1);
        titleArr = new string[](toId-fromId+1);
        startTimeArr = new uint256[](toId-fromId+1);
        endTimeArr = new uint256[](toId-fromId+1);
        proposerArr = new address[](toId-fromId+1);
        proposalTypeArr = new uint256[](toId-fromId+1);
        uint256 i=0;
        for(uint256 id=fromId; id<=toId; id++) {
            idArr[i] = id;
            urlArr[i] = _proposals[id].url;
            titleArr[i] = _proposals[id].title;
            startTimeArr[i] = _proposals[id].startTime;
            endTimeArr[i] = _proposals[id].endTime;
            proposerArr[i] = _proposals[id].proposer;
            proposalTypeArr[i] = _proposals[id].proposalType;
            i = i+1;
        }
        return (idArr,urlArr,titleArr,startTimeArr,endTimeArr,proposerArr,proposalTypeArr);
    }
    function getProposalInfoArr2(uint256 fromId,uint256 toId) public view returns (
        uint256[] memory idArr,
        uint256[] memory minQuorumArr,
        uint256[] memory totalVoteForArr,
        uint256[] memory totalVoteAgainstArr,
        uint256[] memory totalAbstainArr,
        uint256[] memory totalArr,
        uint256[] memory sumCountArr
    ){
        idArr = new uint256[](toId-fromId+1);
        minQuorumArr = new uint256[](toId-fromId+1);
        totalVoteForArr = new uint256[](toId-fromId+1);
        totalVoteAgainstArr = new uint256[](toId-fromId+1);
        totalAbstainArr = new uint256[](toId-fromId+1);
        totalArr = new uint256[](toId-fromId+1);
        sumCountArr = new uint256[](toId-fromId+1);
        uint256 i=0;
        for(uint256 id=fromId; id<=toId; id++) {
            idArr[i] = id;
            minQuorumArr[i] = _proposals[id].minQuorum;
            totalVoteForArr[i] = _proposals[id].totalVoteFor;
            totalVoteAgainstArr[i] = _proposals[id].totalVoteAgainst;
            totalAbstainArr[i] = _proposals[id].totalAbstain;
            totalArr[i] = _proposals[id].totalVoteFor+ _proposals[id].totalVoteAgainst+_proposals[id].totalAbstain;
            sumCountArr[i] = _proposals[id].sumCount;
            i = i+1;
        }
        return (idArr,minQuorumArr,totalVoteForArr,totalVoteAgainstArr,totalAbstainArr,totalArr,sumCountArr);
    }

    function getParameters(address account,uint256 id) public view returns (uint256[] memory){
        uint256[] memory paraList = new uint256[](uint256(20));
        paraList[0]= 0;if(_proposals[id].start && block.timestamp>_proposals[id].startTime)paraList[0]= 1;
        paraList[1]= 0;if(_proposals[id].start && block.timestamp>_proposals[id].endTime)paraList[1]= 1;
        paraList[2]= _proposals[id].proposalType;
        paraList[3]= block.timestamp;
        paraList[4]= _proposals[id].startTime;
        paraList[5]= _proposals[id].endTime;
        paraList[6]= 0;
        paraList[7]= 0;
        paraList[8]= _proposals[id].minQuorum;
        paraList[9]= _proposals[id].totalVoteFor;
        paraList[10]= _proposals[id].totalVoteAgainst;
        paraList[11]= _proposals[id].totalAbstain;
        paraList[12]= _proposals[id].sumCount;

        paraList[13]=0;if(_proposals[id].bAddrVote[account]) paraList[13]=1;
        paraList[14]= _proposals[id].addrWeight[account];
        paraList[15]= _proposals[id].addrWeightType[account];
        paraList[16]= _proposals[id].addrVoteTime[account];
        
        return paraList;
    } 

    function getVoteAddressInfoArr(uint256 id,uint256 fromIth,uint256 toIth) public view returns (
        address[] memory addrArr,
        uint256[] memory addrWeight,
        uint256[] memory addrWeightType,
        uint256[] memory addrVoteTime
    ){
        addrArr = new address[](toIth-fromIth+1);
        addrWeight = new uint256[](toIth-fromIth+1);
        addrWeightType = new uint256[](toIth-fromIth+1);
        addrVoteTime = new uint256[](toIth-fromIth+1);

        uint256 i=0;
        for(uint256 ith=fromIth; ith<=toIth; ith++) {
            addrArr[i] = _proposals[id].voteAddrArr[ith];
            addrWeight[i] =_proposals[id].addrWeight[addrArr[i] ];
            addrWeightType[i] =  _proposals[id].addrWeightType[addrArr[i] ];
            addrVoteTime[i] = _proposals[id].addrVoteTime[addrArr[i] ];
            i = i+1;
        }
        return (addrArr,addrWeight,addrWeightType,addrVoteTime);
    }
    function getVoteAddressInfo(uint256 id,address account) external view returns (uint256,uint256,uint256,uint256) {
        uint256 bvote=0;
        if(_proposals[id].bAddrVote[account])bvote= 1;
        return (bvote,
            _proposals[id].addrWeight[account],
            _proposals[id].addrWeightType[account],
            _proposals[id].addrVoteTime[account]
        );
    }
    function isWhiteAddr(address account) public view returns (bool) {
        return _Is_WhiteAddrArr[account];
    }

    function getWhiteAccountNum() public view returns (uint256){
        return _WhiteAddrArr.length;
    }

    function getWhiteAccountIth(uint256 ith) public view returns (address WhiteAddress){
        require(ith <_WhiteAddrArr.length, " not in White Adress");
        return _WhiteAddrArr[ith];
    }

    //---write---//

    event Submit(address indexed user, uint256 id,uint256 value,uint256 voteType);
    function submit(uint256 id,address account,uint256 value,uint256 voteType) external nonReentrant {
        require(_Is_WhiteAddrArr[_msgSender()], "Account not in white list");
        require(id<=nowId, " not Start!");
        require(_proposals[id].start, " not Start!");
        require(block.timestamp>_proposals[id].startTime, " not Start!");
        require(!_proposals[id].bAddrVote[account], " already vote!");
        require(voteType==0 || voteType==1 || voteType==2, " vote type wrong!");

        if(voteType==0){
            _proposals[id].totalVoteFor =  _proposals[id].totalVoteFor.add(value);
        }
        else if(voteType==1){
            _proposals[id].totalVoteAgainst =  _proposals[id].totalVoteAgainst.add(value);
        }
        else if(voteType==2){
            _proposals[id].totalAbstain =  _proposals[id].totalAbstain.add(value);
        }

        _proposals[id].bAddrVote[account]=true;
        _proposals[id].addrWeight[account]=value;
        _proposals[id].addrWeightType[account]=voteType;
        _proposals[id].addrVoteTime[account]=block.timestamp;

        _proposals[id].sumCount = _proposals[id].sumCount.add(1);
        _proposals[id].voteAddrArr.push(account);

        emit Submit(msg.sender, id, value,voteType);
    }

    //---write onlyOwner---//
    function addWhiteAccount(address account) external onlyOwner{
        require(!_Is_WhiteAddrArr[account], "Account is already in White list");
        _Is_WhiteAddrArr[account] = true;
        _WhiteAddrArr.push(account);
    }
    function addWhiteAccount(address[] calldata  accountArr) external onlyOwner{
        for(uint256 i=0; i<accountArr.length; ++i) {
            require(!_Is_WhiteAddrArr[accountArr[i]], "Account is already in White list");
            _Is_WhiteAddrArr[accountArr[i]] = true;
            _WhiteAddrArr.push(accountArr[i]);     
        }
    }
    function removeWhiteAccount(address account) external onlyOwner{
        require(_Is_WhiteAddrArr[account], "Account is already out White list");
        for (uint256 i = 0; i < _WhiteAddrArr.length; i++){
            if (_WhiteAddrArr[i] == account){
                _WhiteAddrArr[i] = _WhiteAddrArr[_WhiteAddrArr.length - 1];
                _WhiteAddrArr.pop();
                _Is_WhiteAddrArr[account] = false;
                break;
            }
        }
    }

    event CreateVote(address indexed user, string url,string title,uint256 proposalType,uint256 minQuorum, uint256 startTime,uint256 endTime,uint256 id);
    function createVote(string memory url,string memory title,uint256 proposalType,uint256 minQuorum, uint256 startTime,uint256 endTime)external{
        require(_Is_WhiteAddrArr[_msgSender()], "Account not in white list");
        nowId = nowId+1;
        _proposals[nowId].start=true;
        _proposals[nowId].url=url;
        _proposals[nowId].title=title;
        _proposals[nowId].proposalType=proposalType;
        _proposals[nowId].proposer=_msgSender();
        _proposals[nowId].minQuorum=minQuorum;
        _proposals[nowId].endTime=endTime;
        _proposals[nowId].startTime=startTime;
        emit CreateVote(msg.sender, url, title,proposalType,minQuorum,startTime,endTime,nowId);

    }
    event FixVote(address indexed user, string url,string title,uint256 proposalType,uint256 minQuorum, uint256 startTime,uint256 endTime,uint256 id);
    function fixVote(uint256 id,string memory url,string memory title,uint256 proposalType,uint256 minQuorum, uint256 startTime,uint256 endTime)external{
        require(_Is_WhiteAddrArr[_msgSender()], "Account not in white list");
        require(id<=nowId, " not Start!");
        require(_proposals[id].start, " not Start!");
        _proposals[id].url=url;        
        _proposals[id].title=title;
        _proposals[id].proposalType=proposalType;
        _proposals[id].minQuorum=minQuorum;
        _proposals[id].endTime=endTime;
        _proposals[id].startTime=startTime;
        emit FixVote(msg.sender, url,title, proposalType,minQuorum,startTime,endTime,id);
    }
}