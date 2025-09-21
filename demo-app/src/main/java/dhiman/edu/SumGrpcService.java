package dhiman.edu;

import io.quarkus.grpc.GrpcService;
import io.smallrye.mutiny.Uni;

@GrpcService
public class SumGrpcService implements SumService {
	@Override
	public Uni<SumResponse> sum(final SumRequest request) {
		return Uni.createFrom()
			.item(request.getArgOne() + request.getArgTwo())
			.map(res -> SumResponse.newBuilder().setResult(res).build());
	}
}
