---
layout: post
title:  go中interface类型的空值判断
description: 
modified:   2019-03-29 11:44:44
tags: [go]
---

问题场景:
```
// IsModuleSpecExist check if the module spec exists by identify_id
// Exist Check
func (s *Service) IsModuleSpecExist(param *checker.IsModuleSpecExistReq) (bool, error) {
	module := &model.ModuleSpec{
		IdentifyID: param.IdentifyID,
	}
	res, err := s.ModuleSpecDao.List(s.DBOperator, module)
	return genExistCheckRsp(res, err)
}

func genExistCheckRsp(res interface{}, err error) (bool, err) {
	if err != nil {
		return false, err
	} else if res == nil {
		return false, err
	} 
	return true, err
}
```

这段代码，IsModuleSpecExist是为了校验数据库中是否已经存在IdentifyID的记录，写genExistCheckRsp是为了写一个公共的


[参考]: https://juejin.im/post/5c9d5631f265da60d82dde9c
